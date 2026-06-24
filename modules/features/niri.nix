{inputs, ...}: {
  flake.nixosModules.niri = {pkgs, ...}: {
    imports = [inputs.niri.nixosModules.niri];
    nixpkgs.overlays = [inputs.niri.overlays.niri];
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-stable;
    # niri 25.08 auto-spawns xwayland-satellite when it is on PATH
    environment.systemPackages = [pkgs.xwayland-satellite];

    # niri drives screencast through gnome's portal (via the mutter/shell api niri implements itself),
    # but gnome's file-chooser delegation to gtk is broken, so add gtk and route the chooser to it
    xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];
    xdg.portal.config.niri = {
      default = ["gtk" "gnome"];
      "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
      "org.freedesktop.impl.portal.Secret" = ["gnome-keyring"];
    };
  };

  flake.homeModules.niri = {
    pkgs,
    lib,
    config,
    ...
  }: let
    c = config.colors;

    screenshotArea = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-area";
      runtimeInputs = with pkgs; [wayfreeze grim slurp wl-clipboard];
      text = ''
        pgrep -x wayfreeze && exit 0
        wayfreeze --hide-cursor &
        PID=$!
        sleep 0.1
        # shellcheck disable=SC2086
        GEOM=$(slurp $SLURP_ARGS) || { kill "$PID"; exit 0; }
        grim -g "$GEOM" - | wl-copy -t image/png
        kill "$PID"
      '';
    });

    screenshotEdit = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-edit";
      runtimeInputs = with pkgs; [wayfreeze grim slurp satty coreutils];
      text = ''
        pgrep -x wayfreeze && exit 0
        wayfreeze --hide-cursor &
        PID=$!
        sleep 0.1
        # shellcheck disable=SC2086
        GEOM=$(slurp $SLURP_ARGS) || { kill "$PID"; exit 0; }
        TMP=$(mktemp --suffix=.png)
        trap 'rm -f "$TMP"' EXIT
        grim -g "$GEOM" "$TMP"
        kill "$PID"
        satty -f "$TMP"
      '';
    });

    screenshotFull = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-full";
      runtimeInputs = with pkgs; [grim wl-clipboard];
      text = ''
        grim - | wl-copy -t image/png
      '';
    });

    editClipboard = lib.getExe (pkgs.writeShellApplication {
      name = "edit-clipboard";
      runtimeInputs = with pkgs; [wl-clipboard satty];
      text = ''wl-paste | satty -f -'';
    });

    recordToggle = lib.getExe (pkgs.writeShellApplication {
      name = "record-toggle";
      runtimeInputs = with pkgs; [wf-recorder slurp libnotify procps coreutils scowl];
      text = ''
        VIDDIR="$HOME/Videos"
        mkdir -p "$VIDDIR"
        WORDS="${pkgs.scowl}/share/dict/words.txt"

        gen_name() {
          shuf -n 2 "$WORDS" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z\n' | tr '\n' '-' | sed 's/-$//'
        }

        GEOMFILE="/tmp/qs-rec-geom"

        PIDFILE="/tmp/qs-rec-pid"
        FILEFILE="/tmp/qs-rec-file"

        if pgrep -x wf-recorder > /dev/null; then
          pkill -INT -x wf-recorder
          rm -f "$GEOMFILE"
          # wait for wf-recorder to flush and exit
          PID=$(cat "$PIDFILE" 2>/dev/null)
          if [ -n "$PID" ]; then
            tail --pid="$PID" -f /dev/null 2>/dev/null || sleep 2
          fi
          LAST=$(cat "$FILEFILE" 2>/dev/null)
          rm -f "$PIDFILE" "$FILEFILE"
          if [ -n "$LAST" ] && [ -f "$LAST" ]; then
            notify-send -a "recording" -t 3000 "recording saved to ~/videos" "$(basename "$LAST")"
          fi
        else
          pgrep -x slurp && exit 0
          NAME=$(gen_name)
          FILE="$VIDDIR/$NAME.mp4"
          GEOM=$(slurp -b 000000CC -s 00000000) || exit 0
          echo "$GEOM" > "$GEOMFILE"
          echo "$FILE" > "$FILEFILE"
          notify-send -a "recording" -t 2000 "recording started" "super+shift+r to stop"
          wf-recorder -g "$GEOM" -c libx264 -a -f "$FILE" &
          echo $! > "$PIDFILE"
        fi
      '';
    });

    wallpaper = lib.getExe (pkgs.writeShellApplication {
      name = "wallpaper";
      runtimeInputs = with pkgs; [coreutils awww niri jq findutils];
      text = ''
        WALL_DIR="$HOME/dotfiles/wallpapers"

        # wait for awww daemon
        sleep 1

        set_wallpapers() {
          mapfile -t walls < <(find "$WALL_DIR" -type f \( -name '*.jpg' -o -name '*.png' \) | shuf)
          if [ ''${#walls[@]} -eq 0 ]; then return 1; fi

          mapfile -t mons < <(niri msg --json outputs | jq -r 'keys[]')

          for i in "''${!mons[@]}"; do
            mon_name="''${mons[$i]}"
            idx=$((i % ''${#walls[@]}))
            awww img -o "$mon_name" --fill-color 000000 --transition-type grow --transition-pos 0.5,0.5 --transition-duration 1 --transition-fps 60 "''${walls[$idx]}"
          done
        }

        set_wallpapers

        while true; do
          sleep 1800
          set_wallpapers
        done
      '';
    });

    colorPicker = lib.getExe (pkgs.writeShellApplication {
      name = "niri-color-picker";
      runtimeInputs = with pkgs; [niri gnugrep wl-clipboard];
      text = ''
        niri msg pick-color | grep -oP '#[0-9a-fA-F]+' | wl-copy
      '';
    });

    swayosd = lib.getExe' pkgs.swayosd "swayosd-client";
  in {
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    home.sessionVariables = {
      GTK_THEME = "catppuccin-mocha-mauve-standard";
      QT_QPA_PLATFORMTHEME = "kde";
      QT_STYLE_OVERRIDE = "kvantum";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      SDL_VIDEODRIVER = "wayland,x11";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";

      # dark overlay for slurp region selection
      # -b background, -c border, -s selection fill, -w border width (RRGGBBAA)
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

      # monitor scale/position/mode is per-host, discover with `niri msg outputs`

      layout = {
        gaps = 8;
        center-focused-column = "never";
        preset-column-widths = [
          {proportion = 0.333;}
          {proportion = 0.5;}
          {proportion = 0.667;}
          {proportion = 1.0;}
        ];
        default-column-width.proportion = 0.5;
        border = {
          enable = true;
          width = 2;
          active.color = c.accent;
          inactive.color = c.surface0;
        };
        focus-ring.enable = false;
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
        hide-when-typing = true;
      };

      prefer-no-csd = true;
      hotkey-overlay.skip-at-startup = true;

      # named scratch workspace
      workspaces.sandbox = {};

      # vicinae focus fix, debug nodes take a list of kdl args
      debug.honor-xdg-activation-with-invalid-serial = [];

      spawn-at-startup = [
        {command = ["awww-daemon"];}
        {command = [wallpaper];}
        {command = ["${lib.getExe pkgs.wl-clip-persist}" "--clipboard" "regular"];}
        {command = ["vicinae" "server"];}
      ];

      window-rules = [
        {
          matches = [{}];
          geometry-corner-radius = let
            r = 1.0 * c.rounding;
          in {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
        }
        {
          # dim inactive windows
          matches = [{is-active = false;}];
          opacity = 0.95;
        }
        {
          # must be after the dim rule otherwise it'll get written over
          matches = [{app-id = "^(vlc|mpv|com\\.obsproject\\.Studio|.*[Zz]oom.*|org\\.kde\\.kdenlive)$";}];
          opacity = 1.0;
        }
        {
          # file/app choosers run as a separate portal process, niri won't auto-float them
          matches = [{app-id = "^xdg-desktop-portal";}];
          open-floating = true;
          default-column-width.proportion = 0.75;
          default-window-height.proportion = 0.75;
        }
        {
          matches = [{title = "^Picture[ -]in[ -][Pp]icture$";}];
          open-floating = true;
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
            {app-id = "pavucontrol$";}
            {app-id = "^floating-term$";}
          ];
          open-floating = true;
          default-column-width.proportion = 0.75;
          default-window-height.proportion = 0.75;
        }
      ];

      binds = with config.lib.niri.actions; {
        # app launch
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

        # windows
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
        # overview
        "Mod+Backslash" = {
          action = toggle-overview;
          hotkey-overlay.title = "Overview";
        };

        # focus (arrows)
        "Mod+Left" = {
          action = focus-column-left;
          hotkey-overlay.title = "Focus left";
        };
        "Mod+Right".action = focus-column-right;
        "Mod+Up".action = focus-window-up;
        "Mod+Down".action = focus-window-down;

        # focus (vim)
        "Mod+H".action = focus-column-left;
        "Mod+L".action = focus-column-right;
        "Mod+K".action = focus-window-up;
        "Mod+J".action = focus-window-down;

        # move (arrows)
        "Mod+Shift+Left" = {
          action = move-column-left;
          hotkey-overlay.title = "Move left";
        };
        "Mod+Shift+Right".action = move-column-right;
        "Mod+Shift+Up".action = move-window-up;
        "Mod+Shift+Down".action = move-window-down;

        # column stacking
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

        # workspace to monitor
        "Mod+Shift+Alt+Left" = {
          action = move-workspace-to-monitor-left;
          hotkey-overlay.title = "Workspace to monitor left";
        };
        "Mod+Shift+Alt+Right".action = move-workspace-to-monitor-right;
        "Mod+Shift+Alt+Up".action = move-workspace-to-monitor-up;
        "Mod+Shift+Alt+Down".action = move-workspace-to-monitor-down;

        # column scroll
        "Mod+BracketLeft".action = focus-column-left;
        "Mod+BracketRight".action = focus-column-right;
        "Mod+Shift+BracketLeft" = {
          action = move-column-left;
          hotkey-overlay.title = "Swap column left";
        };
        "Mod+Shift+BracketRight".action = move-column-right;

        # width / height
        "Mod+Ctrl+Equal" = {
          action = set-column-width "+5%";
          hotkey-overlay.title = "Widen column";
        };
        "Mod+Ctrl+Minus".action = set-column-width "-5%";
        "Mod+Alt+Equal" = {
          action = switch-preset-column-width;
          hotkey-overlay.title = "Cycle width";
        };
        "Mod+Alt+Minus".action = switch-preset-column-width;
        "Mod+Minus" = {
          action = set-column-width "-100";
          hotkey-overlay.title = "Shrink column";
        };
        "Mod+Equal".action = set-column-width "+100";
        "Mod+Shift+Minus".action = set-window-height "-100";
        "Mod+Shift+Equal".action = set-window-height "+100";

        # first / last / fit
        "Mod+Home" = {
          action = focus-column-first;
          hotkey-overlay.title = "First column";
        };
        "Mod+End".action = focus-column-last;
        "Mod+Shift+Home".action = center-column;
        "Mod+Shift+End".action = expand-column-to-available-width;

        # resize (vim)
        "Mod+Ctrl+H".action = set-column-width "-50";
        "Mod+Ctrl+J".action = set-window-height "+50";
        "Mod+Ctrl+K".action = set-window-height "-50";

        # workspaces
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

        # raw attrset form: niri-flake's parser drops the multi-line MoveWindowToWorkspace
        # variant so it's missing from config.lib.niri.actions, niri validates this directly
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

        # workspace navigation
        "Mod+Tab" = {
          action = focus-workspace-down;
          hotkey-overlay.title = "Next workspace";
        };
        "Mod+Shift+Tab" = {
          action = focus-workspace-up;
          hotkey-overlay.title = "Prev workspace";
        };
        "Mod+Ctrl+Tab".action = focus-workspace-previous;

        # alt-tab, niri only has focus-previous (no cyclenext)
        "Alt+Tab" = {
          action = focus-window-previous;
          hotkey-overlay.title = "Last window";
        };
        "Alt+Shift+Tab".action = focus-window-previous;

        # wheel
        "Mod+WheelScrollDown" = {
          action = focus-column-right;
          cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          action = focus-column-left;
          cooldown-ms = 150;
        };

        # launcher and tools
        "Mod+Space" = {
          action = spawn "vicinae" "toggle";
          hotkey-overlay.title = "Launcher";
        };
        "Mod+V" = {
          action = spawn "vicinae" "vicinae://launch/clipboard/history?toggle=true";
          hotkey-overlay.title = "Clipboard";
        };
        "Mod+Escape" = {
          action = spawn "${pkgs.swaylock-effects}/bin/swaylock";
          hotkey-overlay.title = "Lock";
        };
        "Mod+Shift+W" = {
          action = spawn "vicinae" "vicinae://launch/@sovereign/vicinae-extension-awww-switcher-0/wpgrid?toggle=true";
          hotkey-overlay.title = "Wallpaper picker";
        };
        "Mod+Shift+Slash" = {
          action = spawn "vicinae" "vicinae://launch/@fbad/niri-keybinds-0/niri-keybinds";
          hotkey-overlay.title = "Keybinds";
        };

        # color picker, copies hex to clipboard
        "Mod+Shift+C" = {
          action = spawn colorPicker;
          hotkey-overlay.title = "Color picker";
        };

        # capture (wayfreeze hides cursor and avoids window border artifacts)
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

        # sandbox scratch workspace
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

        # brightness
        "XF86MonBrightnessUp" = {
          action = spawn swayosd "--brightness" "raise";
          allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          action = spawn swayosd "--brightness" "lower";
          allow-when-locked = true;
        };

        # misc keys
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
