_: {
  flake.modules.homeManager.waybar =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.colors;
      tui = cmd: "${lib.getExe pkgs.wezterm} start --class floating-term -- ${cmd}";
      btTui = tui (lib.getExe pkgs.bluetui);
      wifiTui = tui (lib.getExe pkgs.wlctl);
      # setcap wrapper, the store path loses the watts row
      btop = tui "/run/wrappers/bin/btop";
      mixer = lib.getExe pkgs.pwvucontrol;
      wpctl = lib.getExe' pkgs.wireplumber "wpctl";
      systemctl = lib.getExe' pkgs.systemd "systemctl";

      barSpacing = 2;
      gap = {
        pair = 6;
        group = 12;
        section = 20;
      };
      pad = px: toString (builtins.div (px - barSpacing) 2);

      g = cp: builtins.fromJSON ''"\u${cp}"'';

      volIcons = {
        low = "󰕿";
        med = "󰖀";
        high = "󰕾";
        muted = "󰖁";
      };

      memIcon = "󰘚";
    in
    {
      programs.waybar = {
        enable = true;
        systemd.enable = true;

        settings.mainBar = {
          layer = "top";
          height = 30;
          spacing = barSpacing;

          modules-left = [ "niri/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [
            "custom/recording"
            "privacy"
            "wireplumber"
            "wireplumber#mic"
            "network"
            "bluetooth"
            "cpu"
            "temperature"
            "memory"
            "power-profiles-daemon"
            "battery"
            "idle_inhibitor"
          ];

          "niri/workspaces" = {
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
            calendar = {
              iso8601 = true;
              # waybar replaces each span class with the color of #clock.calendar-x below
              format = {
                months = "<span class='months'><b>{}</b></span>";
                weekdays = "<span class='weekdays'><b>{}</b></span>";
                today = "<span class='today'><b><u>{}</u></b></span>";
              };
            };
            actions = {
              on-click-right = "mode";
              on-click-middle = "shift_reset";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };

          privacy = {
            icon-size = 12;
            icon-spacing = 6;
            modules = [
              { type = "screenshare"; }
              { type = "audio-in"; }
            ];
            ignore = [
              {
                type = "audio-in";
                name = "gsr-default_output";
              }
            ];
          };

          "custom/recording" = {
            # ExecStartPost signals while the unit is still activating
            exec = "case $(${systemctl} --user is-active screen-record.service) in active | activating) echo ${g "f111"} ;; esac";
            signal = 8;
            on-click = "record-toggle";
            tooltip = false;
          };

          wireplumber = {
            format = "{icon}  {volume}%";
            format-muted = volIcons.muted;
            format-icons = [
              volIcons.low
              volIcons.med
              volIcons.high
            ];
            on-click = "${mixer} --tab 4";
            on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scroll-step = 5;
          };

          "wireplumber#mic" = {
            node-type = "Audio/Source";
            format = g "f130";
            format-muted = g "f131";
            on-click = "${mixer} --tab 3";
            on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            scroll-step = 5;
            tooltip = false;
          };

          network = {
            interval = 10;
            format-wifi = "${g "f1eb"}  {ipaddr}";
            format-ethernet = "${g "f0e8"}  {ipaddr}";
            format-linked = "${g "f05e"}  no ip";
            format-disconnected = "${g "f05e"}  off";
            format-disabled = "${g "f05e"}  rfkill";
            tooltip-format-wifi = "{essid}  {signalStrength}%\n{ipaddr}/{cidr}\ngw {gwaddr}";
            tooltip-format-ethernet = "{ifname}\n{ipaddr}/{cidr}\ngw {gwaddr}";
            tooltip-format-linked = "{ifname} (no address)";
            tooltip-format-disconnected = "disconnected";
            tooltip-format-disabled = "radio blocked";
            on-click = wifiTui;
          };

          bluetooth = {
            format = g "f293";
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
            hwmon-by-name = "coretemp";
            input-filename = "temp1_input";
            critical-threshold = 90;
            on-click = btop;
          };

          memory = {
            interval = 5;
            format = "${memIcon} {percentage}%";
            tooltip-format = "Total {total:0.1f} GiB\nUsed {used:0.1f} GiB\nAvailable {avail:0.1f} GiB";
            on-click = btop;
          };

          "power-profiles-daemon" = {
            tooltip-format = "power profile: {profile}\ncpu driver: {cpu_driver}\nplatform driver: {platform_driver}";
            format-icons = {
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
            format-icons = [
              (g "f244")
              (g "f243")
              (g "f242")
              (g "f241")
              (g "f240")
            ];
            tooltip-format = "{timeTo} ({power}W)\nhealth {health}% - {cycles} cycles";
          };

          idle_inhibitor = {
            format = "{icon}";
            format-icons = {
              activated = g "f06e";
              deactivated = g "f070";
            };
            tooltip-format-activated = "screenlock disabled";
            tooltip-format-deactivated = "screenlock enabled";
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
            padding: 0 6px;
          }

          #workspaces button {
            color: ${c.overlay0};
            padding: 0 4px;
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

          #clock.calendar-months {
            color: ${c.accent};
          }

          #clock.calendar-weekdays {
            color: ${c.subtext0};
          }

          #clock.calendar-today {
            color: ${c.pink};
          }

          #custom-recording,
          #privacy,
          #wireplumber,
          #network,
          #bluetooth,
          #cpu,
          #temperature,
          #memory,
          #power-profiles-daemon,
          #battery,
          #idle_inhibitor {
            padding: 0 ${pad gap.section}px;
          }

          @keyframes rec-blink {
            to {
              color: alpha(${c.red}, 0.25);
            }
          }

          #custom-recording {
            color: ${c.red};
            animation: rec-blink 1s steps(10) infinite alternate;
          }

          #privacy-item.screenshare {
            color: ${c.red};
          }

          #privacy-item.audio-in {
            color: ${c.yellow};
          }

          #wireplumber {
            color: ${c.pink};
          }

          #wireplumber.mic {
            color: ${c.rosewater};
          }

          #wireplumber.muted {
            color: ${c.overlay0};
          }

          #network {
            color: ${c.accent};
          }

          #network.disconnected,
          #network.linked,
          #network.disabled {
            color: ${c.overlay0};
          }

          #bluetooth {
            color: ${c.sky};
          }

          #bluetooth.disabled,
          #bluetooth.off,
          #bluetooth.no-controller {
            color: ${c.overlay0};
          }

          #cpu {
            color: ${c.lavender};
            padding-right: ${pad gap.pair}px;
          }

          #memory {
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
            padding-left: ${pad gap.group}px;
          }

          #power-profiles-daemon.performance {
            color: ${c.red};
          }

          #power-profiles-daemon.power-saver {
            color: ${c.green};
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
            color: ${c.overlay0};
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
