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

      # catppuccinBuildHook leaves no room for whiskers flags
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

      # only ports whiskers renders, vivid is not one
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

      # gtk theme is in home/gtk.nix
      catppuccin = {
        enable = true;
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
        # papirus has the kde icons dolphin asks for
        gtk.icon.enable = true;
        imv.enable = true;
        mpv.enable = true;
        obs.enable = true;
        # vesktop is themed in home/vesktop.nix
        vivid.enable = true;
        zathura.enable = true;
        zsh-syntax-highlighting.enable = true;
      };
    };
}
