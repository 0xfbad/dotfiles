_: {
  flake.homeModules.waybar = {
    pkgs,
    lib,
    config,
    ...
  }: let
    c = config.colors;
    term = lib.getExe pkgs.wezterm;
    btTui = "${term} start --class floating-term -- ${lib.getExe pkgs.bluetui}";
    wifiTui = "${term} start --class floating-term -- ${pkgs.wlctl}/bin/wlctl";
    btop = "${term} start --class floating-term -- ${pkgs.btop}/bin/btop";
    pavucontrol = lib.getExe pkgs.pavucontrol;
    wpctl = "${pkgs.wireplumber}/bin/wpctl";

    barSpacing = 2;
    gap = {
      pair = 6;
      group = 12;
      section = 20;
    };
    pad = px: toString (builtins.div (px - barSpacing) 2);

    g = cp: builtins.fromJSON ''"\u${cp}"'';

    volIcons = {
      low = builtins.fromJSON ''"󰕿"'';
      med = builtins.fromJSON ''"󰖀"'';
      high = builtins.fromJSON ''"󰕾"'';
      muted = builtins.fromJSON ''"󰖁"'';
    };

    micStatus = pkgs.writeShellScript "waybar-mic" ''
      if ${wpctl} get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -q MUTED; then
        echo '{"text":"${g "f131"}","class":"muted"}'
      else
        echo '{"text":"${g "f130"}","class":"on"}'
      fi
    '';

    memIcon = builtins.fromJSON ''"󰘚"'';

    memInfo = pkgs.writeShellScript "waybar-mem" ''
      ${pkgs.gawk}/bin/awk '
        /^MemTotal:/ { total = $2 }
        /^MemFree:/ { free = $2 }
        /^MemAvailable:/ { avail = $2 }
        /^Cached:/ { cached = $2 }
        /^Buffers:/ { buffers = $2 }
        /^SwapTotal:/ { stotal = $2 }
        /^SwapFree:/ { sfree = $2 }
        END {
          used = total - avail
          pct = used / total * 100
          gib = 1048576
          printf "{\"text\":\"%.0f%%\",\"tooltip\":\"Total %.1f GiB\\nUsed %.1f GiB\\nAvailable %.1f GiB\\nCached %.1f GiB\\nFree %.1f GiB\\nSwap %.1f / %.1f GiB\"}\n", pct, total/gib, used/gib, avail/gib, (cached + buffers)/gib, free/gib, (stotal - sfree)/gib, stotal/gib
        }
      ' /proc/meminfo
    '';
  in {
    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings.mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = barSpacing;

        modules-left = ["niri/workspaces"];
        modules-center = ["clock"];
        modules-right = [
          "wireplumber"
          "custom/mic"
          "network"
          "bluetooth"
          "cpu"
          "temperature"
          "custom/memory"
          "power-profiles-daemon"
          "battery"
          "idle_inhibitor"
        ];

        "niri/workspaces" = {
          all-outputs = false;
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            active = g "f004";
            default = g "f08a";
            urgent = g "f004";
          };
        };

        clock = {
          format = "{:%a, %d %b - %H:%M}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        wireplumber = {
          format = "{icon}  {volume}%";
          format-muted = volIcons.muted;
          format-icons = [volIcons.low volIcons.med volIcons.high];
          on-click = pavucontrol;
          on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
          scroll-step = 5;
        };

        "custom/mic" = {
          exec = "${micStatus}";
          return-type = "json";
          interval = 2;
          on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          on-scroll-up = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 5%+";
          on-scroll-down = "${wpctl} set-volume @DEFAULT_AUDIO_SOURCE@ 5%-";
          tooltip = false;
        };

        network = {
          interval = 10;
          format-wifi = "${g "f1eb"}  {ipaddr}";
          format-ethernet = "${g "f0e8"}  {ipaddr}";
          format-disconnected = "${g "f05e"}  off";
          tooltip-format-wifi = "{essid}  {signalStrength}%\n{ipaddr}/{cidr}\ngw {gwaddr}";
          tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\ngw {gwaddr}";
          tooltip-format-disconnected = "disconnected";
          on-click = wifiTui;
        };

        bluetooth = {
          format = g "f293";
          format-disabled = g "f293";
          format-off = g "f293";
          format-connected = "${g "f293"}  {num_connections}";
          tooltip-format = "{controller_alias}";
          tooltip-format-connected = "{controller_alias}\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}";
          tooltip-format-enumerate-connected-battery = "{device_alias}  {device_battery_percentage}%";
          on-click = btTui;
        };

        cpu = {
          format = "${g "f2db"} {usage}%";
          interval = 5;
          on-click = btop;
        };

        temperature = {
          hwmon-path-abs = "/sys/devices/platform/coretemp.0/hwmon";
          input-filename = "temp1_input";
          critical-threshold = 90;
          format = "{temperatureC}°C";
          format-critical = "{temperatureC}°C";
          on-click = btop;
        };

        "custom/memory" = {
          exec = memInfo;
          return-type = "json";
          interval = 5;
          format = "${memIcon} {}";
          on-click = btop;
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "power profile: {profile}";
          format-icons = {
            default = g "f0e7";
            performance = g "f135";
            balanced = g "f24e";
            power-saver = g "f06c";
          };
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = "${g "f0e7"} {capacity}%";
          format-plugged = "${g "f1e6"} {capacity}%";
          format-icons = [(g "f244") (g "f243") (g "f242") (g "f241") (g "f240")];
          tooltip-format = "{timeTo} ({power}W)";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = g "f06e";
            deactivated = g "f070";
          };
          tooltip-format-activated = "screenlock off";
          tooltip-format-deactivated = "screenlock on";
        };
      };

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12px;
          font-weight: 600;
          min-height: 0;
        }

        window#waybar {
          background: ${c.bg};
          color: ${c.text};
        }

        #workspaces {
          background: transparent;
          margin: 0;
          padding: 0 6px;
        }

        #workspaces button {
          color: ${c.surface1};
          padding: 0;
          background: transparent;
        }

        #workspaces button.active {
          color: ${c.pink};
        }

        #workspaces button.urgent {
          color: ${c.red};
        }

        #workspaces button:hover {
          color: ${c.rosewater};
        }

        #clock {
          color: ${c.pink};
          font-size: 13px;
          font-weight: 700;
        }

        #wireplumber,
        #custom-mic,
        #network,
        #bluetooth,
        #cpu,
        #temperature,
        #custom-memory,
        #power-profiles-daemon,
        #battery,
        #idle_inhibitor {
          background: transparent;
          padding: 0 ${pad gap.section}px;
        }

        #wireplumber {
          color: ${c.pink};
        }

        #wireplumber.muted {
          color: ${c.surface1};
        }

        #custom-mic {
          color: ${c.rosewater};
        }

        #custom-mic.muted {
          color: ${c.surface1};
        }

        #network {
          color: ${c.accent};
        }

        #network.disconnected {
          color: ${c.surface1};
        }

        #bluetooth {
          color: ${c.sky};
        }

        #cpu {
          color: ${c.lavender};
          padding-right: ${pad gap.pair}px;
        }

        #custom-memory {
          color: ${c.flamingo};
          padding-left: ${pad gap.group}px;
          padding-right: ${pad gap.group}px;
        }

        #temperature {
          color: ${c.lavender};
          padding-left: ${pad gap.pair}px;
          padding-right: ${pad gap.group}px;
        }

        #temperature.critical {
          color: ${c.red};
        }

        #power-profiles-daemon {
          color: ${c.peach};
          padding-right: ${pad gap.group}px;
        }

        #battery {
          color: ${c.peach};
        }

        #battery.charging {
          color: ${c.sky};
        }

        #battery.warning:not(.charging) {
          color: ${c.yellow};
        }

        #battery.critical:not(.charging) {
          color: ${c.red};
        }

        #idle_inhibitor {
          color: ${c.surface1};
          padding-right: 18px;
        }

        #idle_inhibitor.activated {
          color: ${c.pink};
        }

        tooltip {
          background: ${c.bg};
          border: 1px solid ${c.surface0};
          border-radius: ${toString c.rounding}px;
        }

        tooltip label {
          color: ${c.text};
        }
      '';
    };
  };
}
