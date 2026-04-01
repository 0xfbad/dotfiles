_: {
  flake.homeModules.waybar = {
    config,
    pkgs,
    ...
  }: let
    c = config.colors;
  in {
    programs.waybar = {
      enable = true;
      systemd.enable = true;
      settings = [
        {
          layer = "top";
          position = "top";
          height = 26;
          spacing = 0;

          modules-left = ["hyprland/workspaces"];
          modules-center = ["clock"];
          modules-right = ["custom/recording" "tray" "bluetooth" "network" "pulseaudio" "pulseaudio#mic" "cpu" "memory" "battery"];

          "hyprland/workspaces" = {
            format = "{icon}";
            format-icons = {
              active = "󱓻";
              default = "󱓼";
            };
            on-click = "activate";
            sort-by-number = true;
          };

          clock = {
            format = "{:%a %b %d  %H:%M:%S}";
            interval = 1;
            tooltip = false;
          };

          cpu = {
            format = "󰘚 {usage}%";
            interval = 5;
            on-click = "${pkgs.wezterm}/bin/wezterm start --class btop -- btop";
          };

          memory = {
            format = "󰍛 {percentage}%";
            tooltip-format = "{used:0.1f}G / {total:0.1f}G";
            interval = 5;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "󰖁 muted";
            format-icons = {
              default = ["󰕿" "󰖀" "󰕾"];
            };
            on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          };

          bluetooth = {
            format-on = "󰂯";
            format-off = "󰂲";
            format-connected = "󰂱 {device_alias}";
            on-click = "${pkgs.wezterm}/bin/wezterm start --class bluetui -- bluetui";
          };

          "pulseaudio#mic" = {
            format = "{format_source}";
            format-source = "󰍬";
            format-source-muted = "󰍭";
            on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            tooltip-format = "Mic: {source_volume}%";
          };

          network = {
            format-wifi = "󰤨 {essid} {signalStrength}% ({ipaddr})";
            format-ethernet = "󰈀 {ipaddr}";
            format-disconnected = "󰤭 disconnected";
            tooltip-format-wifi = "{signalStrength}%  {bandwidthUpBits}  {bandwidthDownBits}";
            tooltip-format-ethernet = "{ifname}: {ipaddr}/{cidr}";
            on-click = "${pkgs.wezterm}/bin/wezterm start --class impala -- impala";
            interval = 5;
          };

          battery = {
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰚥 {capacity}%";
            format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
            states = {
              warning = 20;
              critical = 10;
            };
            tooltip-format = "{timeTo}";
          };

          "custom/recording" = {
            exec = "pgrep -x wf-recorder > /dev/null && echo '󰻂 REC' || echo ''";
            interval = 1;
            return-type = "";
          };

          tray = {
            icon-size = 12;
            spacing = 8;
          };
        }
      ];

      style = ''
        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12px;
          border: none;
          border-radius: 0;
          min-height: 0;
        }

        window#waybar {
          background: ${c.bg};
          color: ${c.text};
        }

        #workspaces button {
          padding: 0 6px;
          margin: 0 1.5px;
          color: ${c.surface1};
          background: transparent;
        }

        #workspaces button.active {
          color: ${c.accent};
        }

        #workspaces button:hover {
          background: ${c.mantle};
        }

        #clock {
          padding: 0 10px;
          color: ${c.text};
        }

        #cpu, #memory, #pulseaudio, #network, #bluetooth, #battery, #tray {
          padding: 0 8px;
          color: ${c.text};
        }

        #pulseaudio.muted {
          color: ${c.surface1};
        }

        #network.disconnected {
          color: ${c.surface1};
        }

        #bluetooth.off {
          color: ${c.surface1};
        }

        #custom-recording {
          color: ${c.red};
          padding: 0 8px;
        }

        #battery.warning {
          color: ${c.red};
        }

        #battery.critical {
          color: ${c.red};
          animation: blink 1s linear infinite;
        }

        @keyframes blink {
          to { color: ${c.bg}; }
        }

        tooltip {
          background: ${c.mantle};
          border: 1px solid ${c.surface0};
          border-radius: 4px;
          padding: 2px;
        }
      '';
    };
  };
}
