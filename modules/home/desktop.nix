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
              # satty disables saving without it
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

        # ships its own spotify, no pkgs.spotify alongside
        spicetify = {
          enable = true;
          theme = spicePkgs.themes.catppuccin;
          colorScheme = "mocha";
        };

        aria2 = {
          enable = true;
          systemd.enable = true;
          settings = {
            dir = "${config.home.homeDirectory}/Downloads";
            # vicinae.nix patches the same literal
            rpc-secret = "vicinae-local";
            continue = true;
            max-connection-per-server = 16;
            min-split-size = "1M";
            split = 16;
          };
        };
      };

      # catppuccin.obs installs the theme but does not select it
      home.activation.obsTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        # obs rewrites it on exit, cannot be a store symlink
        obsIni="$HOME/.config/obs-studio/user.ini"

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
