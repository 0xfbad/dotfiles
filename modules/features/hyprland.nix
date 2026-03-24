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

    whichKeyConfig = pkgs.writeText "which-key.yaml" ''
      font: JetBrainsMono Nerd Font
      background: "#000000"
      color: "#cdd6f4"
      border: "#cba6f7"
      separator: " → "
      border_width: 2
      corner_r: 8
      padding: 16
      anchor: center
      margin_bottom: 0
      margin_top: 0
      margin_left: 0
      margin_right: 0
      entries:
        - { key: Return, desc: terminal }
        - { key: Q, desc: close window }
        - { key: F, desc: maximize }
        - { key: G, desc: fullscreen }
        - { key: S, desc: launcher }
        - { key: V, desc: mic mute }
        - { key: C, desc: center window }
        - { key: H/J/K/L, desc: focus }
        - { key: Shift+H/J/K/L, desc: move window }
        - { key: Shift+Arrow, desc: move to monitor }
        - { key: Ctrl+H/J/K/L, desc: resize }
        - { key: 1-0, desc: workspace }
        - { key: Shift+1-0, desc: move to workspace }
        - { key: Shift+S, desc: screenshot region }
        - { key: Ctrl+S, desc: screenshot full }
        - { key: Shift+E, desc: edit clipboard }
        - { key: Shift+R, desc: record region }
        - { key: Shift+G, desc: record gif }
        - { key: Shift+F, desc: toggle float }
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
      monitor = DP-3, 3440x1440@240, 1440x540, 1

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
      exec-once = ${lib.getExe pkgs.wlr-which-key} ${whichKeyConfig}

      # window management
      bind = ${mod}, Return, exec, ${lib.getExe pkgs.wezterm}
      bind = ${mod}, Q, killactive
      bind = ${mod}, F, fullscreen, 1
      bind = ${mod}, G, fullscreen, 0
      bind = ${mod} SHIFT, F, togglefloating
      bind = ${mod}, C, centerwindow

      # focus
      bind = ${mod}, H, movefocus, l
      bind = ${mod}, L, movefocus, r
      bind = ${mod}, K, movefocus, u
      bind = ${mod}, J, movefocus, d
      bind = ${mod}, Left, movefocus, l
      bind = ${mod}, Right, movefocus, r
      bind = ${mod}, Up, movefocus, u
      bind = ${mod}, Down, movefocus, d

      # move windows
      bind = ${mod} SHIFT, H, movewindow, l
      bind = ${mod} SHIFT, L, movewindow, r
      bind = ${mod} SHIFT, K, movewindow, u
      bind = ${mod} SHIFT, J, movewindow, d

      # move to other monitor
      bind = ${mod} SHIFT, Left, movewindow, mon:l
      bind = ${mod} SHIFT, Right, movewindow, mon:r
      bind = ${mod} SHIFT, Up, movewindow, mon:u
      bind = ${mod} SHIFT, Down, movewindow, mon:d

      # resize
      binde = ${mod} CTRL, H, resizeactive, -50 0
      binde = ${mod} CTRL, L, resizeactive, 50 0
      binde = ${mod} CTRL, J, resizeactive, 0 50
      binde = ${mod} CTRL, K, resizeactive, 0 -50

      # workspaces
      bind = ${mod}, 1, workspace, 1
      bind = ${mod}, 2, workspace, 2
      bind = ${mod}, 3, workspace, 3
      bind = ${mod}, 4, workspace, 4
      bind = ${mod}, 5, workspace, 5
      bind = ${mod}, 6, workspace, 6
      bind = ${mod}, 7, workspace, 7
      bind = ${mod}, 8, workspace, 8
      bind = ${mod}, 9, workspace, 9
      bind = ${mod}, 0, workspace, 10

      bind = ${mod} SHIFT, 1, movetoworkspace, 1
      bind = ${mod} SHIFT, 2, movetoworkspace, 2
      bind = ${mod} SHIFT, 3, movetoworkspace, 3
      bind = ${mod} SHIFT, 4, movetoworkspace, 4
      bind = ${mod} SHIFT, 5, movetoworkspace, 5
      bind = ${mod} SHIFT, 6, movetoworkspace, 6
      bind = ${mod} SHIFT, 7, movetoworkspace, 7
      bind = ${mod} SHIFT, 8, movetoworkspace, 8
      bind = ${mod} SHIFT, 9, movetoworkspace, 9
      bind = ${mod} SHIFT, 0, movetoworkspace, 10

      # scroll navigation
      bind = ${mod}, mouse_down, workspace, e-1
      bind = ${mod}, mouse_up, workspace, e+1

      # keybind hints
      bind = ${mod}, slash, exec, ${lib.getExe pkgs.wlr-which-key} ${whichKeyConfig}

      # launcher
      bind = ${mod}, S, exec, ${noctaliaExe} ipc call launcher toggle
      # mic mute
      bind = ${mod}, V, exec, ${pkgs.alsa-utils}/bin/amixer sset Capture toggle

      # screenshots
      bind = ${mod} SHIFT, S, exec, ${screenshot}
      bind = ${mod} CTRL, S, exec, ${screenshotFull}
      bind = ${mod} SHIFT, E, exec, ${editClipboard}
      bind = , Print, exec, ${screenshotEdit}

      # screen recording
      bind = ${mod} SHIFT, R, exec, ${recordRegion}
      bind = ${mod} CTRL, R, exec, ${recordRegionAudio}
      bind = ${mod} SHIFT, G, exec, ${recordGif}

      # audio
      binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%+
      binde = , XF86AudioLowerVolume, exec, wpctl set-volume -l 1.4 @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      # window rules
      windowrule = tile on, match:class org.wezfurlong.wezterm
    '';
  };
}
