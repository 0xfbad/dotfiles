{ inputs, ... }: {
  flake.modules.homeManager.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      spicePkgs = inputs.spicetify.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      imports = [
        inputs.spicetify.homeManagerModules.spicetify
      ];

      programs = {
        chromium = {
          enable = true;
          package = pkgs.ungoogled-chromium;
        };

        obs-studio.enable = true;

        mpv = {
          enable = true;
          scripts = [ pkgs.mpvScripts.uosc ];
          # uosc replaces the builtin osc and window decorations
          config = {
            osc = false;
            border = false;
          };
        };

        yt-dlp = {
          enable = true;
          settings = {
            embed-metadata = true;
            embed-thumbnail = true;
            sponsorblock-mark = "all";
          };
        };

        satty = {
          enable = true;
          settings = {
            general = {
              # without output-filename satty disables saving entirely
              output-filename = "~/Pictures/satty-%Y-%m-%d_%H:%M:%S.png";
              actions-on-enter = [ "save-to-clipboard" ];
              early-exit = [ "all" ];
              copy-command = "wl-copy";
              initial-tool = "brush";
            };
            color-palette.palette = map (c: "${c}ff") [
              config.colors.red
              config.colors.peach
              config.colors.yellow
              config.colors.green
              config.colors.sky
              config.colors.accent
            ];
          };
        };

        prismlauncher = {
          enable = true;
          settings.ShowConsole = false;
        };

        # installs the patched spotify itself, so no pkgs.spotify alongside it
        spicetify = {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "mocha";
        };

        aria2 = {
          enable = true;
          # the vicinae aria2-manager extension drives the rpc daemon on 6800
          systemd.enable = true;
          settings = {
            dir = "${config.home.homeDirectory}/Downloads";
            continue = true;
            max-connection-per-server = 16;
            min-split-size = "1M";
            split = 16;
          };
        };
      };

      # catppuccin.obs drops the theme files in place, obs still has to be told to load them
      home.activation.obsTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # rewritten on exit so it cannot be a store symlink
        obsIni="$HOME/.config/obs-studio/user.ini"

        # seed only when missing so a theme picked in the ui sticks
        if ! ${pkgs.crudini}/bin/crudini --get "$obsIni" Appearance Theme >/dev/null 2>&1; then
          run mkdir -p "$(dirname "$obsIni")"
          run ${pkgs.crudini}/bin/crudini --set "$obsIni" Appearance Theme com.obsproject.Catppuccin.Mocha
        fi
      '';

      services.awww.enable = true;

      home.packages = with pkgs; [
        torsocks # route any app traffic through tor

        # media
        vlc
        ffmpeg
        gimp-with-plugins

        # communication
        signal-desktop
        zoom-us
        weechat # irc client

        # productivity
        libreoffice
        odt2txt
        kdePackages.kdenlive
        xournalpp # pdf annotation and handwriting

        # screenshots and recording
        imagemagick
        wl-clipboard # provides wl-copy and wl-paste
        pngquant # lossy png compression

        # gaming
        supertuxkart

        # vpn and networking
        openconnect # cisco and juniper vpn client
        wireguard-tools
        remmina # remote desktop client for rdp vnc ssh
      ];
    };
}
