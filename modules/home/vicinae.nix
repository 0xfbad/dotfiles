{ inputs, ... }: {
  flake.modules.homeManager.vicinae =
    {
      config,
      pkgs,
      ...
    }:
    let
      c = config.colors;
      ext = inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
      mkRaycast = inputs.vicinae.lib.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension;
      raycastRev = "05f80223a5cad6e11c71878bf1888e5d44b36c7a";

      mocha.name = "catppuccin-mocha";
    in
    {
      imports = [
        inputs.vicinae.homeManagerModules.default
      ];

      # vicinae launches script commands in the first terminal listed here
      xdg.configFile."xdg-terminals.list".text = ''
        org.wezfurlong.wezterm.desktop
      '';

      programs.vicinae = {
        enable = true;
        systemd.enable = true;

        # the native messaging host only serves the browser-extension provider, disabled below
        enableFirefoxIntegration = false;
        enableChromeIntegration = false;

        # settings go in VICINAE_OVERRIDES, which outranks anything the gui writes to settings.json
        settings = {
          telemetry.system_info = false;
          activate_on_single_click = true;
          pop_to_root_on_close = true;
          keybinding = "vim";

          # missing sqlcipher key crash loops the server, enable only with a pam unlocked keyring
          encrypt_sensitive_data = false;

          launcher_window = {
            size = {
              width = 1100;
              height = 650;
            };
            inherit (c) rounding;
          };

          theme = {
            light = mocha;
            dark = mocha;
          };

          providers = {
            clipboard.preferences.eraseOnStartup = true;

            # the indexer sweeps all of $HOME on a timer, these are churn it can never search usefully
            files.preferences.excludedIndexingPaths = map (p: "${config.home.homeDirectory}/${p}") [
              ".claude"
              ".cache"
              ".mozilla"
              ".var"
              ".local/state"
              ".local/share/Steam"
            ];

            wm.enabled = false;
            developer.enabled = false;
            browser-extension.enabled = false;

            # declarative so a settings.json wipe cannot lose it again
            "@sovereign/vicinae-extension-awww-switcher-0".preferences.wallpaperPath =
              "${config.home.homeDirectory}/dotfiles/wallpapers";

            core.entrypoints = {
              documentation.enabled = false;
              about.enabled = false;
              report-bug.enabled = false;
              sponsor.enabled = false;
              manage-fallback.enabled = false;
              list-extensions.enabled = false;
              oauth-token-store.enabled = false;
              open-config-file.enabled = false;
              open-default-config.enabled = false;
              inspect-local-storage.enabled = false;
              reload-scripts.enabled = false;
              prune-memory.enabled = false;
              search-builtin-icons.enabled = false;
              forget-telemetry.enabled = false;
            };
          };
        };

        extensions =
          map (n: ext.${n}) [
            "nix"
            "case-converter"
            "firefox"
            "number-converter"
            "keepassxc"
            "awww-switcher"
            "dashboard-icons"
            "niri"
            "it-tools"
            "aria2-manager"
          ]
          ++ [
            (mkRaycast {
              name = "tailwindcss";
              rev = raycastRev;
              hash = "sha256-56LjYVHPGUr+zVbZPuXhA5VqhTe86TWqFkV16bzTKDI=";
            })
            (mkRaycast {
              name = "todo-list";
              rev = raycastRev;
              hash = "sha256-4HbJUGhB6Yz7t/lF/saAuCOZg+pYE9S6+t3i0yPMXuM=";
            })
          ];

        themes.catppuccin-mocha = {
          meta = {
            version = 1;
            name = "Catppuccin Mocha";
            description = "Catppuccin mocha OLED with mauve accent";
            variant = "dark";
            inherits = "vicinae-dark";
          };
          colors = {
            core = {
              background = c.bg;
              foreground = c.text;
              secondary_background = c.mantle;
              border = c.surface0;
              inherit (c) accent;
            };
            accents = {
              inherit (c) blue;
              inherit (c) green;
              magenta = c.pink;
              orange = c.peach;
              purple = c.accent;
              inherit (c) red;
              inherit (c) yellow;
              cyan = c.teal;
            };
          };
        };
      };
    };
}
