_: {
  flake.nixosModules.hyprland = _: {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };

  flake.homeModules.hyprland = {
    pkgs,
    lib,
    config,
    ...
  }: let
    c = config.colors;
    ch = config.colors.hypr;

    presentationToggle = lib.getExe (pkgs.writeShellApplication {
      name = "presentation-toggle";
      runtimeInputs = with pkgs; [hyprland jq libnotify];
      text = ''
        state_file="/tmp/hypr-presentation-state"
        state=$(cat "$state_file" 2>/dev/null || echo "extend")

        main=$(hyprctl monitors -j | jq -r '.[0].name')
        mapfile -t all_mons < <(hyprctl monitors all -j | jq -r '.[].name')
        if [ "''${#all_mons[@]}" -lt 2 ]; then
          notify-send -a "display" -t 3000 "presentation" "no external monitor detected"
          exit 0
        fi

        externals=("''${all_mons[@]:1}")

        case "$state" in
          extend)
            for ext in "''${externals[@]}"; do
              hyprctl keyword monitor "$ext, preferred, auto, 1, mirror, $main"
            done
            echo "mirror" > "$state_file"
            notify-send -a "display" -t 3000 "presentation" "mirroring $main"
            ;;
          mirror)
            for ext in "''${externals[@]}"; do
              hyprctl keyword monitor "$ext, preferred, auto-up, 1"
            done
            echo "extend" > "$state_file"
            notify-send -a "display" -t 3000 "presentation" "extended above"
            ;;
        esac
      '';
    });

    wifiTui = pkgs.writeShellScript "wifi-tui" ''
      exec ${pkgs.wlctl}/bin/wlctl
    '';

    screenshotArea = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-area";
      runtimeInputs = with pkgs; [wayfreeze grim slurp wl-clipboard];
      text = ''
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
      runtimeInputs = with pkgs; [wayfreeze grim slurp satty];
      text = ''
        wayfreeze --hide-cursor &
        PID=$!
        sleep 0.1
        # shellcheck disable=SC2086
        GEOM=$(slurp $SLURP_ARGS) || { kill "$PID"; exit 0; }
        grim -g "$GEOM" - | satty -f -
        kill "$PID"
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
      runtimeInputs = with pkgs; [coreutils swww hyprland jq findutils];
      text = ''
        WALL_DIR="$HOME/dotfiles/wallpapers"

        # wait for swww daemon
        sleep 1

        set_wallpapers() {
          mapfile -t walls < <(find "$WALL_DIR" -type f \( -name '*.jpg' -o -name '*.png' \) | shuf)
          if [ ''${#walls[@]} -eq 0 ]; then return 1; fi

          monitors=$(hyprctl monitors -j)
          mon_count=$(echo "$monitors" | jq 'length')

          for i in $(seq 0 $((mon_count - 1))); do
            mon_name=$(echo "$monitors" | jq -r ".[$i].name")
            idx=$((i % ''${#walls[@]}))
            swww img -o "$mon_name" --fill-color 000000 --transition-type grow --transition-pos 0.5,0.5 --transition-duration 1 --transition-fps 60 "''${walls[$idx]}"
          done
        }

        set_wallpapers

        while true; do
          sleep 1800
          set_wallpapers
        done
      '';
    });

    layoutToggle = lib.getExe (pkgs.writeShellApplication {
      name = "hypr-layout-toggle";
      runtimeInputs = with pkgs; [hyprland jq libnotify];
      text = ''
        monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
        current=$(hyprctl getoption general:layout -j | jq -r '.str')

        if [ "$current" = "scrolling" ]; then
          hyprctl keyword general:layout dwindle
          sleep 0.2
          notify-send -a "hyprland" -t 3000 "layout" "dwindle on $monitor"
        else
          hyprctl keyword general:layout scrolling
          sleep 0.2
          notify-send -a "hyprland" -t 3000 "layout" "scrolling on $monitor"
        fi
      '';
    });

    powerMenu = lib.getExe (pkgs.writeShellApplication {
      name = "power-menu";
      runtimeInputs = with pkgs; [coreutils hyprland systemd fuzzel];
      text = ''
        choice=$(printf "lock\nsuspend\nreboot\nlogout\nshutdown" | fuzzel --dmenu)
        case "$choice" in
          lock) hyprlock ;;
          suspend) systemctl suspend ;;
          reboot) systemctl reboot ;;
          logout) hyprctl dispatch exit ;;
          shutdown) systemctl poweroff ;;
        esac
      '';
    });

    popWindow = lib.getExe (pkgs.writeShellApplication {
      name = "hypr-pop-window";
      runtimeInputs = with pkgs; [hyprland];
      text = ''
        hyprctl dispatch togglefloating
        hyprctl dispatch pin
      '';
    });



    mod = "SUPER";
    dynamicCursors = pkgs.hyprlandPlugins.hypr-dynamic-cursors;
  in {
    xdg.configFile."pypr/config.toml".text = ''
      [pyprland]
      plugins = ["scratchpads"]

      [scratchpads.term]
      animation = "fromTop"
      command = "${lib.getExe pkgs.wezterm} start --class dropterm"
      class = "dropterm"
      size = "75% 60%"
      margin = 50
      lazy = true

      [scratchpads.volume]
      animation = "fromRight"
      command = "${lib.getExe pkgs.pavucontrol}"
      class = "org.pulseaudio.pavucontrol"
      size = "40% 90%"
      unfocus = "hide"
      lazy = true
    '';
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    # mutable hyprland.conf: hyprmon writes monitor= lines here, nix config is sourced
    home.activation.hyprlandConf = lib.hm.dag.entryAfter ["writeBoundary"] ''
      HYPR_DIR="$HOME/.config/hypr"
      CONF="$HYPR_DIR/hyprland.conf"
      mkdir -p "$HYPR_DIR"

      MONITORS=""
      if [ -f "$CONF" ] && [ ! -L "$CONF" ]; then
        MONITORS=$(command grep '^monitor' "$CONF" || true)
      fi

      if [ -L "$CONF" ]; then
        rm "$CONF"
      fi

      {
        echo "# monitor config (managed by hyprmon, survives rebuilds)"
        if [ -n "$MONITORS" ]; then
          echo "$MONITORS"
        else
          echo "monitor = , preferred, auto, 1"
        fi
        echo ""
        echo "# nix-generated config"
        echo "source = $HYPR_DIR/hyprland-nix.conf"
      } > "$CONF"
    '';

    xdg.configFile."hypr/hyprland-nix.conf".text = ''
      # plugins
      plugin = ${dynamicCursors}/lib/libhypr-dynamic-cursors.so

      plugin {
        dynamic-cursors {
          enabled = true
          mode = tilt
          shake {
            enabled = true
          }
        }
      }

      # env
      env = HYPRCURSOR_THEME,Bibata-Modern-Classic
      env = HYPRCURSOR_SIZE,24
      env = XCURSOR_THEME,Bibata-Modern-Classic
      env = XCURSOR_SIZE,24
      env = GTK_THEME,catppuccin-mocha-mauve-standard
      env = QT_QPA_PLATFORMTHEME,kde
      env = QT_STYLE_OVERRIDE,kvantum
      env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
      env = GDK_BACKEND,wayland,x11,*
      env = QT_QPA_PLATFORM,wayland;xcb
      env = SDL_VIDEODRIVER,wayland,x11
      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_DESKTOP,Hyprland

      # dark overlay for slurp region selection
      # -b background, -c border, -s selection fill, -w border width (RRGGBBAA)
      env = SLURP_ARGS,-b 000000CC -c ${lib.removePrefix "#" c.accent}ff -s 00000020 -w 2

      # prevent slurp selection border from bleeding into screenshots
      layerrule = no_anim on, match:namespace selection

      # input
      input {
        kb_layout = us
        kb_options = caps:escape
        repeat_rate = 40
        repeat_delay = 250
        follow_mouse = 1
        accel_profile = flat

        touchpad {
          natural_scroll = true
          tap-to-click = true
          disable_while_typing = true
        }
      }

      # general
      general {
        gaps_in = 3
        gaps_out = 5
        border_size = 2
        col.active_border = ${ch.accent}
        col.inactive_border = ${ch.surface0}
        layout = scrolling
      }

      # decoration
      decoration {
        rounding = ${toString c.rounding}
        shadow {
          enabled = false
        }
        blur {
          enabled = false
        }
      }

      # animations
      animations {
        enabled = true
        bezier = quick, 0.25, 0.1, 0.25, 1
        bezier = easeOut, 0.16, 1, 0.3, 1
        animation = windows, 1, 3, quick, popin 80%
        animation = fade, 1, 3, quick
        animation = workspaces, 0
        animation = zoomFactor, 0
      }

      # scrolling layout (niri-like)
      scrolling {
        column_width = 0.5
        fullscreen_on_one_column = true
        focus_fit_method = 1
        follow_focus = true
        follow_min_visible = 0.4
        explicit_column_widths = 0.333, 0.5, 0.667, 1.0
        direction = right
      }

      # dwindle (fallback layout)
      dwindle {
        pseudotile = true
        preserve_split = true
        force_split = 2
      }

      # performance
      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        force_default_wallpaper = 0
        focus_on_activate = true
        vfr = true
      }

      cursor {
        hide_on_key_press = true
      }

      render {
        direct_scanout = true
      }

      xwayland {
        force_zero_scaling = true
      }

      binds {
        hide_special_on_workspace_change = true
        workspace_back_and_forth = true
      }

      general {
        resize_on_border = true
      }


      # startup
      exec-once = swww-daemon
      exec-once = pypr
      exec-once = ${wallpaper}
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      exec-once = ${lib.getExe pkgs.wl-clip-persist} --clipboard regular
      exec-once = wl-paste --watch cliphist store
      exec-once = ${lib.getExe pkgs.hyprdim} --no-dim-when-only --persist --strength 30 --duration 800
      # quickshell managed by systemd user service

      # window rules
      windowrule = match:class .*, suppress_event maximize
      windowrule = match:title ^(Open|Save|Save As|File Upload), float on, center on
      windowrule = match:class ^(btop|bluetui|wifi-tui|wlctl|org.pulseaudio.pavucontrol)$, float on, center on, size (monitor_w*0.75) (monitor_h*0.75)

      windowrule = match:class ^(vlc|mpv|com.obsproject.Studio|zoom|org.kde.kdenlive)$, opacity 1.0 override 1.0 override
      windowrule = match:class ^(zoom)$, float on
      windowrule = match:class ^(zoom)$, match:title ^(menu window|confirm window)$, stay_focused on
      windowrule = match:fullscreen 1, idle_inhibit on

      # PIP (picture-in-picture)
      windowrule = match:title ^(Picture-in-Picture)$, float on, pin on, move 73% 72%, size 25% 25%

      # xwayland video bridge fix
      windowrule = match:class ^(xwaylandvideobridge)$, opacity 0.0 override, no_anim on, no_initial_focus on, max_size 1 1, no_blur on

      # app launch
      bindd = ${mod}, Return, terminal, exec, ${lib.getExe pkgs.wezterm}
      bindd = ${mod} SHIFT, F, file manager, exec, dolphin
      bindd = ${mod} SHIFT, B, browser, exec, firefox

      # windows
      bindd = ${mod}, W, close, killactive
      bindd = ${mod}, F, fullscreen, fullscreen, 1
      bindd = ${mod} CTRL, F, true fullscreen, fullscreen, 0
      bindd = ${mod}, T, float, togglefloating
      bindd = ${mod}, J, toggle split, layoutmsg, togglesplit
      bindd = ${mod}, P, presentation toggle, exec, ${presentationToggle}
      bindd = ${mod} ALT, G, ungroup, moveoutofgroup
      bindd = ${mod}, O, pop out, exec, ${popWindow}
      bindd = ${mod}, C, center, centerwindow

      # scratchpads (pyprland)
      bindd = ${mod}, A, dropdown terminal, exec, pypr toggle term
      bindd = ${mod} SHIFT, V, volume mixer, exec, pypr toggle volume

      # scratchpad workspace
      bindd = ${mod}, S, scratchpad, togglespecialworkspace, scratchpad
      bindd = ${mod} ALT, S, to scratchpad, movetoworkspacesilent, special:scratchpad

      # focus (arrows)
      bindd = ${mod}, Left, focus left, movefocus, l
      bind = ${mod}, Right, movefocus, r
      bind = ${mod}, Up, movefocus, u
      bind = ${mod}, Down, movefocus, d

      # focus (vim, J taken by togglesplit)
      bindd = ${mod}, H, focus left, movefocus, l
      bind = ${mod}, L, movefocus, r
      bind = ${mod}, K, movefocus, u

      # swap windows
      bindd = ${mod} SHIFT, Left, swap left, swapwindow, l
      bind = ${mod} SHIFT, Right, swapwindow, r
      bind = ${mod} SHIFT, Up, swapwindow, u
      bind = ${mod} SHIFT, Down, swapwindow, d

      # move workspace to monitor
      bindd = ${mod} SHIFT ALT, Left, workspace to monitor, movecurrentworkspacetomonitor, l
      bind = ${mod} SHIFT ALT, Right, movecurrentworkspacetomonitor, r
      bind = ${mod} SHIFT ALT, Up, movecurrentworkspacetomonitor, u
      bind = ${mod} SHIFT ALT, Down, movecurrentworkspacetomonitor, d

      # scrolling layout controls
      bindd = ${mod}, bracketleft, scroll left, layoutmsg, move -col
      bind = ${mod}, bracketright, layoutmsg, move +col
      bindd = ${mod} SHIFT, bracketleft, swap col left, layoutmsg, swapcol l
      bind = ${mod} SHIFT, bracketright, layoutmsg, swapcol r
      bindde = ${mod} CTRL, equal, widen column, layoutmsg, colresize +0.05
      binde = ${mod} CTRL, minus, layoutmsg, colresize -0.05
      bindd = ${mod} ALT, equal, next preset width, layoutmsg, colresize +conf
      bind = ${mod} ALT, minus, layoutmsg, colresize -conf
      bindd = ${mod}, Home, focus first, layoutmsg, focus b
      bind = ${mod}, End, layoutmsg, focus e
      bindd = ${mod} SHIFT, Home, fit visible, layoutmsg, fit visible
      bindd = ${mod} SHIFT, End, fit all, layoutmsg, fit all

      # resize (vim)
      bindde = ${mod} CTRL, H, resize left, resizeactive, -50 0
      binde = ${mod} CTRL, L, resizeactive, 50 0
      binde = ${mod} CTRL, J, resizeactive, 0 50
      binde = ${mod} CTRL, K, resizeactive, 0 -50

      # resize (minus/equal)
      bindde = ${mod}, minus, shrink, resizeactive, -100 0
      binde = ${mod}, equal, resizeactive, 100 0
      binde = ${mod} SHIFT, minus, resizeactive, 0 -100
      binde = ${mod} SHIFT, equal, resizeactive, 0 100

      # workspaces
      bindd = ${mod}, 1, workspace 1, workspace, 1
      bind = ${mod}, 2, workspace, 2
      bind = ${mod}, 3, workspace, 3
      bind = ${mod}, 4, workspace, 4
      bind = ${mod}, 5, workspace, 5
      bind = ${mod}, 6, workspace, 6
      bind = ${mod}, 7, workspace, 7
      bind = ${mod}, 8, workspace, 8
      bind = ${mod}, 9, workspace, 9
      bind = ${mod}, 0, workspace, 10

      bindd = ${mod} SHIFT, 1, move to 1, movetoworkspace, 1
      bind = ${mod} SHIFT, 2, movetoworkspace, 2
      bind = ${mod} SHIFT, 3, movetoworkspace, 3
      bind = ${mod} SHIFT, 4, movetoworkspace, 4
      bind = ${mod} SHIFT, 5, movetoworkspace, 5
      bind = ${mod} SHIFT, 6, movetoworkspace, 6
      bind = ${mod} SHIFT, 7, movetoworkspace, 7
      bind = ${mod} SHIFT, 8, movetoworkspace, 8
      bind = ${mod} SHIFT, 9, movetoworkspace, 9
      bind = ${mod} SHIFT, 0, movetoworkspace, 10

      # workspace navigation
      bindd = ${mod}, Tab, next workspace, workspace, e+1
      bindd = ${mod} SHIFT, Tab, prev workspace, workspace, e-1
      bindd = ${mod} CTRL, Tab, last workspace, workspace, previous

      # cycle windows
      bindd = ALT, Tab, cycle windows, cyclenext
      bind = ALT, Tab, bringactivetotop
      bindd = ALT SHIFT, Tab, cycle prev, cyclenext, prev
      bind = ALT SHIFT, Tab, bringactivetotop

      # scroll workspaces
      bindd = ${mod}, mouse_down, scroll layout, layoutmsg, move +col
      bind = ${mod}, mouse_up, layoutmsg, move -col

      # window groups
      bindd = ${mod} ALT, Left, into group left, moveintogroup, l
      bind = ${mod} ALT, Right, moveintogroup, r
      bind = ${mod} ALT, Up, moveintogroup, u
      bind = ${mod} ALT, Down, moveintogroup, d
      bindd = ${mod} ALT, Tab, next in group, changegroupactive, f
      bindd = ${mod} ALT SHIFT, Tab, prev in group, changegroupactive, b

      # mouse
      bindm = ${mod}, mouse:272, movewindow
      bindm = ${mod}, mouse:273, resizewindow

      # launcher and tools
      bindd = ${mod}, Space, launcher, global, quickshell:toggle-launcher
      bindd = ${mod}, V, clipboard, global, quickshell:toggle-clipboard
      bindd = ${mod} CTRL, L, lock, exec, hyprlock
      bindd = ${mod}, Escape, power menu, global, quickshell:toggle-session
      bindd = ${mod} SHIFT, W, wallpaper picker, global, quickshell:toggle-wallpicker
      bindd = ${mod}, backslash, toggle layout, exec, ${layoutToggle}

      # which-key cheatsheet (quickshell native)
      bindd = ${mod}, D, which-key menu, global, quickshell:toggle-cheatsheet

      # notifications
      bindd = ${mod}, comma, dismiss notification, global, quickshell:dismiss-notif
      bindd = ${mod} SHIFT, comma, dismiss all, global, quickshell:dismiss-all-notif
      bindd = ${mod}, N, notification panel, global, quickshell:toggle-notif-panel

      # color picker (copies hex to clipboard)
      bindd = ${mod} SHIFT, C, color picker, exec, ${lib.getExe pkgs.hyprpicker} -a -n

      # capture (wayfreeze hides cursor and avoids window border artifacts)
      bindd = , Print, screenshot region, exec, ${screenshotArea}
      bindd = ${mod} SHIFT, S, screenshot + edit, exec, ${screenshotEdit}
      bindd = ${mod} CTRL, S, screenshot full, exec, ${screenshotFull}
      bindd = ${mod} SHIFT, E, edit clipboard, exec, ${editClipboard}
      bindd = ${mod} SHIFT, R, record toggle, exec, ${recordToggle}

      # audio (quickshell osd detects changes via pipewire)
      bindde = , XF86AudioRaiseVolume, volume up, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
      bindde = , XF86AudioLowerVolume, volume down, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bindd = , XF86AudioMute, mute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
      bindd = , XF86AudioMicMute, mic mute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle

      # brightness (quickshell osd detects changes via polling)
      bindde = , XF86MonBrightnessUp, brightness up, exec, ${pkgs.brightnessctl}/bin/brightnessctl set +5%
      bindde = , XF86MonBrightnessDown, brightness down, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-

      # calculator
      bindd = , XF86Calculator, calculator, exec, ${lib.getExe pkgs.qalculate-gtk}

      # presentation mode (cycles: extend above -> mirror -> off)
      bindd = , XF86Display, presentation toggle, exec, ${presentationToggle}

      # screen zoom at cursor (10% increments, 1.0 to 10.0)
      binde = ${mod} CTRL, mouse_down, exec, hyprctl keyword cursor:zoom_factor "$(awk "BEGIN{v=$(hyprctl getoption cursor:zoom_factor -j | ${pkgs.jq}/bin/jq '.float')+0.1; printf \"%.1f\", (v>10?10:v)}")"
      binde = ${mod} CTRL, mouse_up, exec, hyprctl keyword cursor:zoom_factor "$(awk "BEGIN{v=$(hyprctl getoption cursor:zoom_factor -j | ${pkgs.jq}/bin/jq '.float')-0.1; printf \"%.1f\", (v<1?1:v)}")"

      # media keys
      bindd = , XF86AudioPlay, play/pause, exec, ${lib.getExe pkgs.playerctl} play-pause
      bindd = , XF86AudioNext, next track, exec, ${lib.getExe pkgs.playerctl} next
      bindd = , XF86AudioPrev, prev track, exec, ${lib.getExe pkgs.playerctl} previous
      bindd = , XF86AudioStop, stop, exec, ${lib.getExe pkgs.playerctl} stop
    '';
  };
}
