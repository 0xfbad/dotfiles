_: {
  flake.modules.nixos.networking =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # stay on the wpa_supplicant backend, iwd breaks this wifi driver
      networking.networkmanager.enable = true;

      # resolved.nix defines this at plain priority, a differing value fails eval without the force
      networking.networkmanager.dns = lib.mkForce "none";
      # dns=none still hands dhcp resolvers to resolved which queries past dnscrypt
      networking.networkmanager.settings.main.systemd-resolved = false;
      networking.nameservers = [
        "127.0.0.1"
        "::1"
      ];

      # scanning is already randomised by default, association is not
      networking.networkmanager.ethernet.macAddress = "stable";
      # stable-ssid ignores connection.stable-id, stable takes the daily seed below
      networking.networkmanager.wifi.macAddress = "stable";

      # per network mac that rolls daily, nm has no time placeholder so a service reseeds a runtime conf
      systemd.services.nm-daily-stable-id = {
        description = "Reseed the NetworkManager wifi stable-id for today";
        before = [ "NetworkManager.service" ];
        wantedBy = [ "NetworkManager.service" ];
        path = [ pkgs.networkmanager ];
        serviceConfig.Type = "oneshot";
        script = ''
          # runtime conf.d parses before NetworkManager.conf and loses to anything it defines
          conf=/run/NetworkManager/conf.d/50-daily-stable-id.conf
          seed="[connection-wifi-daily]
          match-device=type:wifi
          connection.stable-id=\''${NETWORK_SSID}-$(date +%Y%m%d)"

          # rebuilds pull this unit in too, do not churn the link on a same day run
          if [ "$seed" = "$(cat "$conf" 2>/dev/null)" ]; then
            exit 0
          fi

          mkdir -p /run/NetworkManager/conf.d
          printf '%s\n' "$seed" > "$conf"

          # the mac is chosen at activation so a live link must reconnect, at boot nothing is up yet
          if systemctl is-active --quiet NetworkManager.service; then
            nmcli general reload conf
            nmcli -g UUID,TYPE connection show --active | while IFS=: read -r uuid type; do
              if [ "$type" = "802-11-wireless" ]; then
                nmcli connection up uuid "$uuid"
              fi
            done
          fi
        '';
      };

      # no Persistent, the run at boot already covers a missed rollover
      systemd.timers.nm-daily-stable-id = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnCalendar = "daily";
      };

      networking.firewall.enable = true;
      networking.nftables.enable = true;

      assertions = [
        {
          assertion = config.services.dnscrypt-proxy.enable;
          message = "networking.nameservers points at loopback, dnscrypt-proxy must be enabled";
        }
      ];

      # do not block boot waiting for a link
      systemd.services.NetworkManager-wait-online.enable = false;

      # restart in one step instead of stop then start, shortens the outage during activation
      systemd.services.NetworkManager.stopIfChanged = false;
    };
}
