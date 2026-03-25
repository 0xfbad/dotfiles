{self, ...}: {
  flake.nixosModules.hyprland = {pkgs, ...}: {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
  };

  flake.homeModules.hyprland = {
    pkgs,
    lib,
    ...
  }: let
    noctaliaExe = lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.noctalia-shell;

    screenshot = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-region";
      runtimeInputs = with pkgs; [grim slurp wl-clipboard];
      text = ''grim -g "$(slurp -w 0)" - | wl-copy'';
    });

    screenshotEdit = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-edit";
      runtimeInputs = with pkgs; [grim slurp imagemagick swappy];
      text = ''grim -g "$(slurp)" - | magick - -shave 1x1 - | swappy -f -'';
    });

    screenshotFull = lib.getExe (pkgs.writeShellApplication {
      name = "screenshot-full";
      runtimeInputs = with pkgs; [grim wl-clipboard];
      text = ''grim -l 0 - | wl-copy'';
    });

    editClipboard = lib.getExe (pkgs.writeShellApplication {
      name = "edit-clipboard";
      runtimeInputs = with pkgs; [wl-clipboard swappy];
      text = ''wl-paste | swappy -f -'';
    });

    recordRegion = lib.getExe (pkgs.writeShellApplication {
      name = "record-region";
      runtimeInputs = with pkgs; [wf-recorder slurp];
      text = ''wf-recorder -g "$(slurp)"'';
    });

    recordRegionAudio = lib.getExe (pkgs.writeShellApplication {
      name = "record-region-audio";
      runtimeInputs = with pkgs; [wf-recorder slurp];
      text = ''wf-recorder -g "$(slurp)" --audio'';
    });

    recordGif = lib.getExe (pkgs.writeShellApplication {
      name = "record-gif";
      runtimeInputs = with pkgs; [wf-recorder slurp];
      text = ''wf-recorder -g "$(slurp)" -c gif -f /tmp/recording.gif'';
    });

    wallpaper = lib.getExe (
      pkgs.writeShellScriptBin "wallpaper"
      "${lib.getExe pkgs.mpvpaper} '*' ${./../../wallpapers/dark-particles.mp4} --mpv-options '--loop --no-audio --speed=0.8 --panscan=1.0'"
    );

    mod = "SUPER";

    keybindTheme = pkgs.writeText "keybind-rofi.rasi" ''
      * {
        background-color: #000000FF;
        text-color: #cdd6f4FF;
      }
      window {
        border: 2px solid;
        border-color: #cba6f7FF;
        border-radius: 8px;
        padding: 24px;
      }
      textbox {
        font: "JetBrainsMono Nerd Font 12";
      }
    '';

    keybindPopup = pkgs.writeShellScriptBin "keybind-popup" ''
            text=$(cat <<'HELPEOF'
      <b>WINDOWS</b>
      Super + Enter                 terminal
      Super + Q                     close window
      Super + F                     maximize
      Super + G                     fullscreen
      Super + Shift + F             float
      Super + C                     center

      <b>FOCUS</b>
      Super + [H/J/K/L]         navigate
      Super + Arrows                navigate
      Super + Shift + [H/J/K/L] move window
      Super + Shift + Arrows        to monitor
      Super + Ctrl + [H/J/K/L]  resize

      <b>WORKSPACES</b>
      Super + [1-0]                 switch workspace
      Super + Shift + [1-0]         move to workspace
      Super + Scroll                cycle workspaces

      <b>CAPTURE</b>
      Super + Shift + S             screenshot region
      Super + Ctrl + S              screenshot full
      Super + Shift + E             edit clipboard
      Print                         screenshot and edit
      Super + Shift + R             record region
      Super + Ctrl + R              record with audio
      Super + Shift + G             record gif

      <b>SYSTEM</b>
      Super + S                     launcher
      Super + V                     mic mute
      Volume Up / Down / Mute       audio
      Super + Shift + ?             this overlay

      <small>press escape or enter to close</small>
      HELPEOF
      )
            lines=$(echo "$text" | wc -l)
            height=$(( lines * 22 + 48 ))
            ${lib.getExe pkgs.rofi} -e "$text" -markup -theme ${keybindTheme} -theme-str "window { width: ''${height}px; height: ''${height}px; }"
    '';
  in {
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    xdg.configFile."hypr/hyprland.conf".text = ''
      # monitors
      monitor = DP-2, 2560x1440@240, 0x0, 1, transform, 1
      monitor = DP-3, 3440x1440@240, 1440x545, 1

      # cursor
      env = HYPRCURSOR_THEME,Bibata-Modern-Classic
      env = HYPRCURSOR_SIZE,24
      env = XCURSOR_THEME,Bibata-Modern-Classic
      env = XCURSOR_SIZE,24

      # input
      input {
        kb_layout = us
        repeat_rate = 40
        repeat_delay = 250
        follow_mouse = 1
        accel_profile = flat

        touchpad {
          natural_scroll = true
          tap-to-click = true
        }
      }

      general {
        gaps_in = 0
        gaps_out = 0
        border_size = 2
        col.active_border = rgb(fab387)
        col.inactive_border = rgb(000000)
        layout = dwindle
      }

      decoration {
        rounding = 0
        shadow {
          enabled = false
        }
        blur {
          enabled = false
        }
      }

      animations {
        enabled = false
      }

      dwindle {
        pseudotile = false
        preserve_split = true
      }

      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
        force_default_wallpaper = 0
      }

      # startup
      exec-once = ${noctaliaExe}
      exec-once = ${wallpaper}

      # windows
      bindd = ${mod}, Return, windows: terminal, exec, ${lib.getExe pkgs.wezterm}
      bindd = ${mod}, Q, windows: close, killactive
      bindd = ${mod}, F, windows: maximize, fullscreen, 1
      bindd = ${mod}, G, windows: fullscreen, fullscreen, 0
      bindd = ${mod} SHIFT, F, windows: float, togglefloating
      bindd = ${mod}, C, windows: center, centerwindow

      # focus
      bindd = ${mod}, H, focus: navigate (H J K L), movefocus, l
      bind = ${mod}, L, movefocus, r
      bind = ${mod}, K, movefocus, u
      bind = ${mod}, J, movefocus, d
      bindd = ${mod}, Left, focus: navigate (← → ↑ ↓), movefocus, l
      bind = ${mod}, Right, movefocus, r
      bind = ${mod}, Up, movefocus, u
      bind = ${mod}, Down, movefocus, d

      # focus: move
      bindd = ${mod} SHIFT, H, focus: move (⇧ H J K L), movewindow, l
      bind = ${mod} SHIFT, L, movewindow, r
      bind = ${mod} SHIFT, K, movewindow, u
      bind = ${mod} SHIFT, J, movewindow, d

      # focus: monitor
      bindd = ${mod} SHIFT, Left, focus: to monitor (⇧ ← → ↑ ↓), movewindow, mon:l
      bind = ${mod} SHIFT, Right, movewindow, mon:r
      bind = ${mod} SHIFT, Up, movewindow, mon:u
      bind = ${mod} SHIFT, Down, movewindow, mon:d

      # focus: resize
      bindd = ${mod} CTRL, H, focus: resize (Ctrl H J K L), resizeactive, -50 0
      binde = ${mod} CTRL, L, resizeactive, 50 0
      binde = ${mod} CTRL, J, resizeactive, 0 50
      binde = ${mod} CTRL, K, resizeactive, 0 -50

      # workspaces
      bindd = ${mod}, 1, workspaces: switch (1 – 0), workspace, 1
      bind = ${mod}, 2, workspace, 2
      bind = ${mod}, 3, workspace, 3
      bind = ${mod}, 4, workspace, 4
      bind = ${mod}, 5, workspace, 5
      bind = ${mod}, 6, workspace, 6
      bind = ${mod}, 7, workspace, 7
      bind = ${mod}, 8, workspace, 8
      bind = ${mod}, 9, workspace, 9
      bind = ${mod}, 0, workspace, 10

      bindd = ${mod} SHIFT, 1, workspaces: move to (⇧ 1 – 0), movetoworkspace, 1
      bind = ${mod} SHIFT, 2, movetoworkspace, 2
      bind = ${mod} SHIFT, 3, movetoworkspace, 3
      bind = ${mod} SHIFT, 4, movetoworkspace, 4
      bind = ${mod} SHIFT, 5, movetoworkspace, 5
      bind = ${mod} SHIFT, 6, movetoworkspace, 6
      bind = ${mod} SHIFT, 7, movetoworkspace, 7
      bind = ${mod} SHIFT, 8, movetoworkspace, 8
      bind = ${mod} SHIFT, 9, movetoworkspace, 9
      bind = ${mod} SHIFT, 0, movetoworkspace, 10

      bindd = ${mod}, mouse_down, workspaces: scroll, workspace, e-1
      bind = ${mod}, mouse_up, workspace, e+1

      # system
      # hold super for ~1s to see keybind help
      bind = ${mod} SHIFT, slash, exec, ${lib.getExe keybindPopup}
      bindd = ${mod}, S, system: launcher, exec, ${noctaliaExe} ipc call launcher toggle
      bindd = ${mod}, V, system: mic mute, exec, ${pkgs.alsa-utils}/bin/amixer sset Capture toggle

      # capture
      bindd = ${mod} SHIFT, S, capture: screenshot region, exec, ${screenshot}
      bindd = ${mod} CTRL, S, capture: screenshot full, exec, ${screenshotFull}
      bindd = ${mod} SHIFT, E, capture: edit clipboard, exec, ${editClipboard}
      bindd = , Print, capture: screenshot and edit, exec, ${screenshotEdit}
      bindd = ${mod} SHIFT, R, capture: record region, exec, ${recordRegion}
      bindd = ${mod} CTRL, R, capture: record with audio, exec, ${recordRegionAudio}
      bindd = ${mod} SHIFT, G, capture: record gif, exec, ${recordGif}

      # system: audio
      bindde = , XF86AudioRaiseVolume, system: volume up, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+
      bindde = , XF86AudioLowerVolume, system: volume down, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-
      bindd = , XF86AudioMute, system: mute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    '';
  };
}
