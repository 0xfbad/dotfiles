{ inputs, ... }: {
  flake.modules.nixos.niri =
    { pkgs, lib, ... }:
    {
      imports = [ inputs.niri.nixosModules.niri ];
      nixpkgs.overlays = [ inputs.niri.overlays.niri ];
      programs.niri.enable = true;
      # niri-flake is less up to date than nixpkgs
      programs.niri.package = pkgs.niri;

      # setcap kms helper, no polkit prompts
      programs.gpu-screen-recorder.enable = true;

      # gnome-keyring from niri-flake claims org.freedesktop.secrets before keepassxc fdosecrets can
      services.gnome.gnome-keyring.enable = lib.mkForce false;

      # hypridle cannot delay suspend on niri
      systemd.services.lock-before-sleep = {
        description = "Lock sessions before sleep";
        before = [ "sleep.target" ];
        wantedBy = [ "sleep.target" ];
        serviceConfig.Type = "oneshot";
        path = [
          pkgs.systemd
          pkgs.procps
          pkgs.coreutils
        ];
        script = ''
          loginctl lock-sessions
          for _ in $(seq 20); do
            if pgrep -x hyprlock >/dev/null; then exit 0; fi
            sleep 0.1
          done
        '';
      };

      # the gnome portal file chooser is broken, add gtk and route choosers to it
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      xdg.portal.config.niri = {
        default = [
          "gtk"
          "gnome"
        ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };

      # hyprlock needs this pam stack, programs.hyprlock.enable also adds hypridle and hyprland
      security.pam.services.hyprlock = { };
    };

  flake.modules.homeManager.niri =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.colors;

      screenshotArea = lib.getExe (
        pkgs.writeShellApplication {
          name = "screenshot-area";
          runtimeInputs = with pkgs; [
            wayfreeze
            grim
            slurp
            wl-clipboard
            procps
            coreutils
          ];
          text = ''
            pgrep -x wayfreeze > /dev/null && exit 0

            wayfreeze --hide-cursor &
            FREEZE=$!
            # without a trap any later failure leaves the frozen overlay covering the session
            trap 'kill "$FREEZE" 2>/dev/null || true' EXIT
            sleep 0.1

            # shellcheck disable=SC2086
            GEOM=$(slurp ''${SLURP_ARGS:-}) || exit 0
            grim -g "$GEOM" - | wl-copy -t image/png
          '';
        }
      );

      screenshotEdit = lib.getExe (
        pkgs.writeShellApplication {
          name = "screenshot-edit";
          runtimeInputs = with pkgs; [
            wayfreeze
            grim
            slurp
            satty
            procps
            coreutils
          ];
          text = ''
            pgrep -x wayfreeze > /dev/null && exit 0

            wayfreeze --hide-cursor &
            FREEZE=$!
            unfreeze() { kill "$FREEZE" 2>/dev/null || true; }
            trap unfreeze EXIT
            sleep 0.1

            # shellcheck disable=SC2086
            GEOM=$(slurp ''${SLURP_ARGS:-}) || exit 0

            TMP=$(mktemp --suffix=.png)
            trap 'unfreeze; rm -f "$TMP"' EXIT

            grim -g "$GEOM" "$TMP"
            unfreeze
            satty -f "$TMP"
          '';
        }
      );

      screenshotFull = lib.getExe (
        pkgs.writeShellApplication {
          name = "screenshot-full";
          runtimeInputs = with pkgs; [
            grim
            wl-clipboard
          ];
          text = ''
            grim - | wl-copy -t image/png
          '';
        }
      );

      editClipboard = lib.getExe (
        pkgs.writeShellApplication {
          name = "edit-clipboard";
          runtimeInputs = with pkgs; [
            wl-clipboard
            satty
          ];
          text = "wl-paste | satty -f -";
        }
      );

      recordToggle = lib.getExe (
        pkgs.writeShellApplication {
          name = "record-toggle";
          runtimeInputs = with pkgs; [
            gpu-screen-recorder
            slurp
            libnotify
            procps
            coreutils
            gnused
            gnugrep
          ];
          text = ''
            VIDDIR="$HOME/Videos"
            mkdir -p "$VIDDIR"
            WORDS="${pkgs.scowl}/share/dict/words.txt"

            gen_name() {
              shuf -n 2 "$WORDS" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z\n' | tr '\n' '-' | sed 's/-$//'
            }

            PIDFILE="/tmp/qs-rec-pid"
            FILEFILE="/tmp/qs-rec-file"

            # pgrep cannot match the wrapped gsr binary
            PID=$(cat "$PIDFILE" 2>/dev/null || true)
            if [ -n "$PID" ] && grep -qa gpu-screen-recorder "/proc/$PID/cmdline" 2>/dev/null; then
              # sigint finalizes the mp4
              kill -INT "$PID" 2>/dev/null || true
              for _ in $(seq 50); do
                kill -0 "$PID" 2>/dev/null || break
                sleep 0.1
              done
              if kill -0 "$PID" 2>/dev/null; then
                kill -9 "$PID" 2>/dev/null || true
                notify-send -u critical -a "recording" -t 5000 "recording force-killed" "file may be corrupt"
              fi
              LAST=$(cat "$FILEFILE" 2>/dev/null || true)
              rm -f "$PIDFILE" "$FILEFILE"
              if [ -n "$LAST" ] && [ -f "$LAST" ]; then
                notify-send -a "recording" -t 3000 "recording saved to ~/videos" "$(basename "$LAST")"
              fi
            else
              pgrep -x slurp && exit 0
              NAME=$(gen_name)
              FILE="$VIDDIR/$NAME.mp4"
              GEOM=$(slurp -f "%wx%h+%x+%y" -b 000000CC -s 00000000) || exit 0
              echo "$FILE" > "$FILEFILE"
              notify-send -a "recording" -t 2000 "recording started" "super+shift+r to stop"

              gpu-screen-recorder -w region -region "$GEOM" -f 60 -fm cfr \
                -a default_output -ac aac -fallback-cpu-encoding yes -o "$FILE" &
              echo $! > "$PIDFILE"
            fi
          '';
        }
      );

      colorPicker = lib.getExe (
        pkgs.writeShellApplication {
          name = "niri-color-picker";
          runtimeInputs = [
            config.programs.niri.package
            pkgs.gnugrep
            pkgs.wl-clipboard
            pkgs.coreutils
          ];
          text = ''
            # cancelling the picker still exits 0, so an unguarded wl-copy would publish an empty selection
            HEX=$(niri msg pick-color | grep -oP '#[0-9a-fA-F]+' | head -n1) || exit 0
            [ -n "$HEX" ] || exit 0
            printf '%s' "$HEX" | wl-copy -n
          '';
        }
      );

      swayosd = lib.getExe' pkgs.swayosd "swayosd-client";
    in
    {
      # name and package come from the catppuccin cursors port, setting them here collides
      home.pointerCursor = {
        enable = true;
        size = 24;
        gtk.enable = true;
      };

      services.wl-clip-persist.enable = true;

      home.sessionVariables = {
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        QT_QPA_PLATFORM = "wayland;xcb";
        SDL_VIDEODRIVER = "wayland,x11";

        # -b background -c border -s selection fill -w border width, colors are RRGGBBAA
        SLURP_ARGS = "-b 000000CC -c ${lib.removePrefix "#" c.accent}ff -s 00000020 -w 2";
      };

      programs.niri.settings = {
        input = {
          keyboard = {
            xkb = {
              layout = "us";
              options = "caps:escape";
            };
            repeat-delay = 250;
            repeat-rate = 40;
          };
          touchpad = {
            tap = true;
            natural-scroll = true;
            dwt = true;
            accel-profile = "flat";
          };
          mouse.accel-profile = "flat";
          focus-follows-mouse.enable = true;
        };

        # clipboard managers still reach the primary selection through data-control
        clipboard.disable-primary = true;

        xwayland-satellite.path = lib.getExe pkgs.xwayland-satellite;

        # monitor scale, position and mode are per host, discover with niri msg outputs
        layout = {
          gaps = 8;
          preset-column-widths = [
            { proportion = 0.333; }
            { proportion = 0.5; }
            { proportion = 0.667; }
            { proportion = 1.0; }
          ];
          default-column-width.proportion = 0.5;
          border = {
            enable = true;
            width = 2;
            active.color = c.accent;
            inactive.color = c.surface0;
          };
          focus-ring.enable = false;
          # unset values fall back to rust defaults not the shipped kdl
          background-color = c.bg;
          insert-hint.display.color = c.accent;
          tab-indicator = {
            position = "left";
            gap = 4;
            hide-when-single-tab = true;
            active.color = c.accent;
            inactive.color = c.surface0;
          };
        };

        overview.backdrop-color = c.bg;

        # blur and background-effect wait on niri-flake types, raw kdl replaces the whole settings block
        cursor = {
          theme = "catppuccin-mocha-mauve-cursors";
          size = 24;
          hide-when-typing = true;
          hide-after-inactive-ms = 5000;
        };

        prefer-no-csd = true;
        hotkey-overlay.skip-at-startup = true;

        workspaces.sandbox = { };

        # vicinae focus fix, debug nodes take a list of kdl args
        debug.honor-xdg-activation-with-invalid-serial = [ ];

        window-rules = [
          {
            matches = [ { } ];
            geometry-corner-radius =
              let
                r = 1.0 * c.rounding;
              in
              {
                top-left = r;
                top-right = r;
                bottom-left = r;
                bottom-right = r;
              };
            clip-to-geometry = true;
          }
          {
            # keeps the vault out of screencasts and wlr-screencopy, not just the portal
            matches = [ { app-id = "^org\\.keepassxc\\.KeePassXC$"; } ];
            block-out-from = "screen-capture";
          }
          {
            # choosers run as a separate portal process, niri does not float them by itself
            matches = [ { app-id = "^xdg-desktop-portal"; } ];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
            # top centers horizontally, y is the offset from the edge
            default-floating-position = {
              x = 0;
              y = 48;
              relative-to = "top";
            };
          }
          {
            matches = [ { title = "^Picture[ -]in[ -][Pp]icture$"; } ];
            open-floating = true;
            default-floating-position = {
              x = 32;
              y = 32;
              relative-to = "bottom-right";
            };
          }
          {
            # zoom is xwayland, float only its popups so the main and meeting windows stay tiled
            matches = [
              {
                app-id = "(?i)zoom";
                title = "(?i)menu";
              }
              {
                app-id = "(?i)zoom";
                title = "(?i)confirm";
              }
              {
                app-id = "(?i)zoom";
                title = "(?i)options$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              { app-id = "^com\\.saivert\\.pwvucontrol$"; }
              { app-id = "^floating-term$"; }
            ];
            open-floating = true;
            default-column-width.proportion = 0.75;
            default-window-height.proportion = 0.75;
          }
        ];

        binds = with config.lib.niri.actions; {
          "Mod+Return" = {
            action = spawn (lib.getExe pkgs.wezterm);
            hotkey-overlay.title = "Terminal";
          };
          "Mod+Shift+F" = {
            action = spawn "dolphin";
            hotkey-overlay.title = "File manager";
          };
          "Mod+Shift+B" = {
            action = spawn "firefox";
            hotkey-overlay.title = "Browser";
          };

          "Mod+W" = {
            action = close-window;
            hotkey-overlay.title = "Close";
          };
          "Mod+F" = {
            action = maximize-column;
            hotkey-overlay.title = "Maximize";
          };
          "Mod+Ctrl+F" = {
            action = fullscreen-window;
            hotkey-overlay.title = "Fullscreen";
          };
          "Mod+T" = {
            action = toggle-window-floating;
            hotkey-overlay.title = "Toggle float";
          };
          "Mod+C" = {
            action = center-column;
            hotkey-overlay.title = "Center";
          };
          "Mod+O" = {
            action = switch-focus-between-floating-and-tiling;
            hotkey-overlay.title = "Float/tile focus";
          };
          "Mod+Shift+T" = {
            action = toggle-column-tabbed-display;
            hotkey-overlay.title = "Tabbed column";
          };
          "Mod+Shift+Q" = {
            action = quit;
            hotkey-overlay.title = "Exit niri";
          };
          "Mod+Backslash" = {
            action = toggle-overview;
            hotkey-overlay.title = "Overview";
          };

          "Mod+Left" = {
            action = focus-column-left;
            hotkey-overlay.title = "Focus left";
          };
          "Mod+Right".action = focus-column-right;
          "Mod+Up".action = focus-window-up;
          "Mod+Down".action = focus-window-down;

          "Mod+H".action = focus-column-left;
          "Mod+L".action = focus-column-right;
          "Mod+K".action = focus-window-up;
          "Mod+J".action = focus-window-down;

          "Mod+Shift+Left" = {
            action = move-column-left;
            hotkey-overlay.title = "Move left";
          };
          "Mod+Shift+Right".action = move-column-right;
          "Mod+Shift+Up".action = move-window-up;
          "Mod+Shift+Down".action = move-window-down;

          "Mod+Alt+Left" = {
            action = consume-or-expel-window-left;
            hotkey-overlay.title = "Consume/expel left";
          };
          "Mod+Alt+Right".action = consume-or-expel-window-right;
          "Mod+Alt+Down" = {
            action = consume-window-into-column;
            hotkey-overlay.title = "Consume into column";
          };
          "Mod+Alt+Up" = {
            action = expel-window-from-column;
            hotkey-overlay.title = "Expel from column";
          };

          "Mod+Shift+Alt+Left" = {
            action = move-workspace-to-monitor-left;
            hotkey-overlay.title = "Workspace to monitor left";
          };
          "Mod+Shift+Alt+Right".action = move-workspace-to-monitor-right;
          "Mod+Shift+Alt+Up".action = move-workspace-to-monitor-up;
          "Mod+Shift+Alt+Down".action = move-workspace-to-monitor-down;

          "Mod+BracketLeft".action = focus-column-left;
          "Mod+BracketRight".action = focus-column-right;
          "Mod+Shift+BracketLeft" = {
            action = move-column-left;
            hotkey-overlay.title = "Swap column left";
          };
          "Mod+Shift+BracketRight".action = move-column-right;

          "Mod+Ctrl+Equal" = {
            action = set-column-width "+5%";
            hotkey-overlay.title = "Widen column";
          };
          "Mod+Ctrl+Minus".action = set-column-width "-5%";
          "Mod+Alt+Equal" = {
            action = switch-preset-column-width;
            hotkey-overlay.title = "Cycle width";
          };
          "Mod+Alt+Minus".action = switch-preset-column-width-back;
          "Mod+Minus" = {
            action = set-column-width "-100";
            hotkey-overlay.title = "Shrink column";
          };
          "Mod+Equal".action = set-column-width "+100";
          "Mod+Shift+Minus".action = set-window-height "-100";
          "Mod+Shift+Equal".action = set-window-height "+100";

          "Mod+Home" = {
            action = focus-column-first;
            hotkey-overlay.title = "First column";
          };
          "Mod+End".action = focus-column-last;
          "Mod+Shift+Home".action = move-column-to-first;
          "Mod+Shift+End".action = expand-column-to-available-width;

          "Mod+Ctrl+H".action = set-column-width "-50";
          "Mod+Ctrl+J".action = set-window-height "+50";
          "Mod+Ctrl+K".action = set-window-height "-50";
          "Mod+Ctrl+L".action = set-column-width "+50";

          "Mod+1" = {
            action = focus-workspace 1;
            hotkey-overlay.title = "Workspace 1";
          };
          "Mod+2".action = focus-workspace 2;
          "Mod+3".action = focus-workspace 3;
          "Mod+4".action = focus-workspace 4;
          "Mod+5".action = focus-workspace 5;
          "Mod+6".action = focus-workspace 6;
          "Mod+7".action = focus-workspace 7;
          "Mod+8".action = focus-workspace 8;
          "Mod+9".action = focus-workspace 9;
          "Mod+0".action = focus-workspace 10;

          # the niri-flake parser drops the MoveWindowToWorkspace variant, raw attrset goes to niri directly
          "Mod+Shift+1" = {
            action.move-window-to-workspace = 1;
            hotkey-overlay.title = "Move to workspace 1";
          };
          "Mod+Shift+2".action.move-window-to-workspace = 2;
          "Mod+Shift+3".action.move-window-to-workspace = 3;
          "Mod+Shift+4".action.move-window-to-workspace = 4;
          "Mod+Shift+5".action.move-window-to-workspace = 5;
          "Mod+Shift+6".action.move-window-to-workspace = 6;
          "Mod+Shift+7".action.move-window-to-workspace = 7;
          "Mod+Shift+8".action.move-window-to-workspace = 8;
          "Mod+Shift+9".action.move-window-to-workspace = 9;
          "Mod+Shift+0".action.move-window-to-workspace = 10;

          "Mod+Tab" = {
            action = focus-workspace-down;
            hotkey-overlay.title = "Next workspace";
          };
          "Mod+Shift+Tab" = {
            action = focus-workspace-up;
            hotkey-overlay.title = "Prev workspace";
          };
          "Mod+Ctrl+Tab".action = focus-workspace-previous;

          # the builtin mru switcher claims Alt+Tab, Alt+Shift+Tab and Alt+Grave, binds here would shadow it

          "Mod+WheelScrollDown" = {
            action = focus-column-right;
            cooldown-ms = 150;
          };
          "Mod+WheelScrollUp" = {
            action = focus-column-left;
            cooldown-ms = 150;
          };

          "Mod+Space" = {
            action = spawn "vicinae" "toggle";
            hotkey-overlay.title = "Launcher";
          };
          "Mod+V" = {
            action = spawn "vicinae" "vicinae://launch/clipboard/history?toggle=true";
            hotkey-overlay.title = "Clipboard";
          };
          # the logind Lock signal drives the hypridle lock handler and keepassxc screen lock
          "Mod+Escape" = {
            action = spawn (lib.getExe' pkgs.systemd "loginctl") "lock-session";
            hotkey-overlay.title = "Lock";
          };
          "Mod+Shift+W" = {
            action = spawn "vicinae" "vicinae://launch/@sovereign/vicinae-extension-awww-switcher-0/wpgrid?toggle=true";
            hotkey-overlay.title = "Wallpaper picker";
          };
          "Mod+Shift+Slash" = {
            action = show-hotkey-overlay;
            hotkey-overlay.title = "Keybinds";
          };

          "Mod+Shift+C" = {
            action = spawn colorPicker;
            hotkey-overlay.title = "Color picker";
          };

          # wayfreeze in the capture scripts hides the cursor and avoids window border artifacts
          "Print" = {
            action = spawn screenshotArea;
            hotkey-overlay.title = "Screenshot region";
          };
          "Mod+Shift+S" = {
            action = spawn screenshotEdit;
            hotkey-overlay.title = "Screenshot edit";
          };
          "Mod+Ctrl+S" = {
            action = spawn screenshotFull;
            hotkey-overlay.title = "Screenshot full";
          };
          "Mod+Shift+E" = {
            action = spawn editClipboard;
            hotkey-overlay.title = "Edit clipboard";
          };
          "Mod+Shift+R" = {
            action = spawn recordToggle;
            hotkey-overlay.title = "Record";
          };

          "Mod+S" = {
            action = focus-workspace "sandbox";
            hotkey-overlay.title = "Sandbox";
          };
          "Mod+Alt+S" = {
            action.move-window-to-workspace = "sandbox";
            hotkey-overlay.title = "Send to sandbox";
          };

          # audio, routed through swayosd so the osd shows
          "XF86AudioRaiseVolume" = {
            action = spawn swayosd "--output-volume" "raise";
            allow-when-locked = true;
          };
          "XF86AudioLowerVolume" = {
            action = spawn swayosd "--output-volume" "lower";
            allow-when-locked = true;
          };
          "XF86AudioMute" = {
            action = spawn swayosd "--output-volume" "mute-toggle";
            allow-when-locked = true;
          };
          "XF86AudioMicMute" = {
            action = spawn swayosd "--input-volume" "mute-toggle";
            allow-when-locked = true;
          };

          "XF86MonBrightnessUp" = {
            action = spawn swayosd "--brightness" "raise";
            allow-when-locked = true;
          };
          "XF86MonBrightnessDown" = {
            action = spawn swayosd "--brightness" "lower";
            allow-when-locked = true;
          };

          "XF86Calculator" = {
            action = spawn (lib.getExe pkgs.qalculate-gtk);
            hotkey-overlay.title = "Calculator";
          };
          "XF86AudioPlay" = {
            action = spawn (lib.getExe pkgs.playerctl) "play-pause";
            allow-when-locked = true;
          };
          "XF86AudioNext" = {
            action = spawn (lib.getExe pkgs.playerctl) "next";
            allow-when-locked = true;
          };
          "XF86AudioPrev" = {
            action = spawn (lib.getExe pkgs.playerctl) "previous";
            allow-when-locked = true;
          };
          "XF86AudioStop" = {
            action = spawn (lib.getExe pkgs.playerctl) "stop";
            allow-when-locked = true;
          };
        };
      };
    };
}
