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
      term = lib.getExe pkgs.wezterm;
      btTui = "${term} start --class floating-term -- ${lib.getExe pkgs.bluetui}";
      wifiTui = "${term} start --class floating-term -- ${pkgs.wlctl}/bin/wlctl";
      # the setcap wrapper, not the store path, or the watts row disables itself
      btop = "${term} start --class floating-term -- /run/wrappers/bin/btop";
      mixer = lib.getExe pkgs.pwvucontrol;
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

        # master for hwmon-by-name and calendar css classes, cava off until nixpkgs ships libcava 1.0.0
        # TEMP: pin before #5212, because shared gtk tooltip cache leaks a modules text into another
        package = (pkgs.waybar.override { cavaSupport = false; }).overrideAttrs (old: {
          version = "0.15.0-unstable-2026-07-21";
          src = pkgs.fetchFromGitHub {
            owner = "Alexays";
            repo = "Waybar";
            rev = "7fae3d7d4341b74272ba43ce90a851e8710f4612";
            hash = "sha256-g8gXdHTQG+Ie653+NIt501LG6+gjg6wVGoRs/y+jIms=";
          };
          # master requires mm-glib for its new modem module
          buildInputs = old.buildInputs ++ [ pkgs.modemmanager ];
          # meson still declares 0.15.0 on master, so the version check cannot match
          doInstallCheck = false;
        });

        settings.mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = barSpacing;

          modules-left = [ "niri/workspaces" ];
          modules-center = [ "clock" ];
          modules-right = [
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
              mode = "month";
              # monday first regardless of system locale
              iso8601 = true;
              # waybar rewrites class='x' into the color it reads off #clock.calendar-x
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
          };

          wireplumber = {
            format = "{icon}  {volume}%";
            format-muted = volIcons.muted;
            format-icons = [
              volIcons.low
              volIcons.med
              volIcons.high
            ];
            on-click = mixer;
            on-click-right = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
            scroll-step = 5;
          };

          "wireplumber#mic" = {
            node-type = "Audio/Source";
            format = g "f130";
            format-muted = g "f131";
            on-click = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
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
            # resolved by /sys/class/hwmon/*/name, so the hwmon index can shuffle freely
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
            format = "{icon}";
            tooltip-format = "power profile: {profile}\ndriver: {driver}";
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
            timeout = 60;
            tooltip-format-activated = "screenlock off - {timeleft}m left";
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

          /* only read to color the {calendar} tooltip, so they have to outrank #clock */
          #clock.calendar-months {
            color: ${c.accent};
          }

          #clock.calendar-weekdays {
            color: ${c.subtext0};
          }

          #clock.calendar-today {
            color: ${c.pink};
          }

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
            background: transparent;
            padding: 0 ${pad gap.section}px;
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

          #wireplumber.muted {
            color: ${c.overlay0};
          }

          /* 0.15.0 tags source modules with .muted too, so .mic wins on order */
          #wireplumber.mic {
            color: ${c.rosewater};
          }

          #wireplumber.mic.muted,
          #wireplumber.mic.source-muted {
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
            padding-right: ${pad gap.section}px;
          }

          #power-profiles-daemon.performance {
            color: ${c.red};
          }

          #power-profiles-daemon.balanced {
            color: ${c.peach};
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
