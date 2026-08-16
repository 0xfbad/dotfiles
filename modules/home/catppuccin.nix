{ inputs, ... }: {
  flake.modules.homeManager.catppuccin =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ports = inputs.catppuccin.packages.${pkgs.stdenv.hostPlatform.system};

      colorOverrides = builtins.toJSON {
        mocha.base = lib.removePrefix "#" config.colors.bg;
      };

      # catppuccinBuildHook runs whiskers with no room for flags, so the phase is restated
      oled =
        drv:
        drv.overrideAttrs (_: {
          buildPhase = ''
            runHook preBuild

            templates=()
            concatTo templates whiskersTemplates

            for template in "''${templates[@]}"; do
              whiskers --color-overrides '${colorOverrides}' "$template"
            done

            runHook postBuild
          '';
        });

      # only the ports whiskers renders, vivid just names a theme the app carries
      oledPorts = [
        "broot"
        "eza"
        "fzf"
        "glamour"
        "imv"
        "mpv"
        "obs"
        "zathura"
        "zsh-syntax-highlighting"
      ];
    in
    {
      imports = [ inputs.catppuccin.homeModules.catppuccin ];

      # the gtk theme has no upstream port and stays in home/gtk.nix
      catppuccin = {
        enable = true;
        # everything needing the OLED base is regenerated above or themed from config.colors
        autoEnable = false;
        flavor = "mocha";
        accent = "mauve";
        sources = ports // lib.genAttrs oledPorts (port: oled ports.${port});

        broot.enable = true;
        cursors.enable = true;
        eza.enable = true;
        fzf.enable = true;
        gh-dash.enable = true;
        glamour.enable = true;
        # papirus, it carries the kde mimetype and action icons dolphin asks for
        gtk.icon.enable = true;
        imv.enable = true;
        mpv.enable = true;
        obs.enable = true;
        vesktop.enable = true;
        vivid.enable = true;
        zathura.enable = true;
        zsh-syntax-highlighting.enable = true;
      };
    };
}
