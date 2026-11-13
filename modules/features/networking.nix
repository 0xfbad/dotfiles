_: {
  flake.modules.nixos.networking =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      networking.networkmanager.enable = true; # iwd breaks the laptop intel ax card, stay on wpa_supplicant

      networking.networkmanager.dns = lib.mkForce "none"; # the resolved module sets systemd-resolved, dhcp resolvers would bypass dnscrypt
      networking.networkmanager.settings.main.systemd-resolved = false; # dns=none still forwards dhcp resolvers to resolved
      networking.nameservers = [
        "127.0.0.1"
        "::1"
      ];

      environment.etc."hosts".mode = "0644"; # hostctl edits last until the next activation
      environment.systemPackages = [ pkgs.hostctl ];

      networking.networkmanager.ethernet.macAddress = "stable";
      networking.networkmanager.wifi.macAddress = "stable"; # stable-ssid ignores connection.stable-id

      systemd.services.nm-daily-stable-id = {
        description = "Reseed the NetworkManager wifi stable-id for today";
        before = [ "NetworkManager.service" ];
        wantedBy = [ "NetworkManager.service" ];
        path = [ pkgs.networkmanager ];
        serviceConfig.Type = "oneshot";
        startAt = "daily";
        script = ''
          conf=/run/NetworkManager/conf.d/50-daily-stable-id.conf # NetworkManager.conf overrides this dir
          seed="[connection-wifi-daily]
          match-device=type:wifi
          connection.stable-id=\''${NETWORK_SSID}-$(date +%Y%m%d)" # no date placeholder in stable-id

          if [ "$seed" = "$(cat "$conf" 2>/dev/null)" ]; then
            exit 0
          fi

          mkdir -p /run/NetworkManager/conf.d
          printf '%s\n' "$seed" > "$conf"

          if ! systemctl is-active --quiet NetworkManager.service; then
            exit 0
          fi

          nmcli general reload conf
          nmcli -g UUID,TYPE connection show --active | while IFS=: read -r uuid type; do
            if [ "$type" = "802-11-wireless" ]; then
              nmcli connection up uuid "$uuid"
            fi
          done
        '';
      };

      # syncthing runs under home-manager
      networking.firewall.allowedTCPPorts = [ 22000 ];
      networking.firewall.allowedUDPPorts = [
        22000
        21027
      ];
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
