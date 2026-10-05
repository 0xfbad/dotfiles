_: {
  flake.modules.nixos.networking =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      networking.networkmanager.enable = true; # iwd breaks this wifi driver

      networking.networkmanager.dns = lib.mkForce "none"; # resolved.nix sets a conflicting value
      networking.networkmanager.settings.main.systemd-resolved = false; # dns=none still forwards dhcp resolvers to resolved
      networking.nameservers = [
        "127.0.0.1"
        "::1"
      ];

      environment.etc."hosts".mode = "0644"; # activation replaces edits with generated host entries
      environment.systemPackages = [ pkgs.hostctl ];

      networking.networkmanager.ethernet.macAddress = "stable";
      networking.networkmanager.wifi.macAddress = "stable"; # stable-ssid ignores connection.stable-id

      systemd.services.nm-daily-stable-id = {
        description = "Reseed the NetworkManager wifi stable-id for today";
        before = [ "NetworkManager.service" ];
        wantedBy = [ "NetworkManager.service" ];
        path = [ pkgs.networkmanager ];
        serviceConfig.Type = "oneshot";
        script = ''
          conf=/run/NetworkManager/conf.d/50-daily-stable-id.conf # NetworkManager.conf overrides runtime snippets
          seed="[connection-wifi-daily]
          match-device=type:wifi
          connection.stable-id=\''${NETWORK_SSID}-$(date +%Y%m%d)" # networkmanager has no date placeholder for the stable id

          if [ "$seed" = "$(cat "$conf" 2>/dev/null)" ]; then
            exit 0
          fi

          mkdir -p /run/NetworkManager/conf.d
          printf '%s\n' "$seed" > "$conf"

          if systemctl is-active --quiet NetworkManager.service; then
            nmcli general reload conf
            nmcli -g UUID,TYPE connection show --active | while IFS=: read -r uuid type; do
              if [ "$type" = "802-11-wireless" ]; then
                nmcli connection up uuid "$uuid" # the mac is chosen during activation
              fi
            done
          fi
        '';
      };

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

      systemd.services.NetworkManager-wait-online.enable = false;

      systemd.services.NetworkManager.stopIfChanged = false;
    };
}
