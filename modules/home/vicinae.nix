{inputs, ...}: {
  flake.homeModules.vicinae = {
    config,
    pkgs,
    lib,
    ...
  }: let
    c = config.colors;
    ext = inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system};
    mkRaycast = inputs.vicinae.packages.${pkgs.stdenv.hostPlatform.system}.mkRayCastExtension;
    raycastRev = "05f80223a5cad6e11c71878bf1888e5d44b36c7a";

    # write settings to a separate file and import it from settings.json
    # avoids the circular import bug with VICINAE_OVERRIDES + nix store paths
    settingsJson = builtins.toJSON {
      telemetry.system_info = false;
      activate_on_single_click = true;
      favicon_service = "twenty";
      pop_to_root_on_close = true;
      escape_key_behavior = "navigate_back";
      pop_on_backspace = true;
      clipboard.clear_on_startup = true;

      launcher_window.size = {
        width = 1100;
        height = 650;
      };

      theme.dark = {
        name = "catppuccin-mocha";
        icon_theme = "auto";
      };

      providers = {
        applications.preferences.launchPrefix = "uwsm app -- ";

        wm.enabled = false;
        power.enabled = false;
        developer.enabled = false;
        browser-extension.enabled = false;

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
          join-discord-server.enabled = false;
        };
      };
    };
  in {
    imports = [
      inputs.vicinae.homeManagerModules.default
    ];

    # wezterm as preferred terminal for script commands
    xdg.configFile."xdg-terminals.list".text = ''
      org.wezfurlong.wezterm.desktop
    '';

    # nix-managed settings, imported by settings.json
    xdg.configFile."vicinae/nix-settings.json".text = settingsJson;

    # deep merge nix provider config into settings.json on rebuild
    # imports can't carry providers because settings.json providers key takes precedence
    home.activation.vicinaeSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
      CONF="$HOME/.config/vicinae/settings.json"
      NIX="$HOME/.config/vicinae/nix-settings.json"
      mkdir -p "$(dirname "$CONF")"
      [ ! -f "$CONF" ] && echo '{"$schema":"https://vicinae.com/schemas/config.json"}' > "$CONF"
      command grep -v '^\s*//' "$CONF" | ${pkgs.jq}/bin/jq --argjson nix "$(cat "$NIX")" '
        .imports = [(.imports // [] | .[] | select(. != "~/.config/vicinae/nix-settings.json")), "~/.config/vicinae/nix-settings.json"] |
        .providers = ((.providers // {}) * ($nix.providers // {}))
      ' > "$CONF.tmp" && mv "$CONF.tmp" "$CONF"
    '';

    services.vicinae = {
      enable = true;
      systemd.enable = true;

      extensions =
        builtins.map (n: ext.${n}) [
          "nix"
          "process-manager"
          "case-converter"
          "firefox"
          "wikipedia"
          "number-converter"
          "keepassxc"
          "awww-switcher"
          "dashboard-icons"
          "fuzzy-files"
          "hypr-keybinds"
          "hyprland-monitors"
          "bluetooth"
          "wifi-commander"
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
            name = "hacker-news";
            rev = raycastRev;
            hash = "sha256-5PpTCgki2Pdm8IxaCo+RXg69h1Tl1/OQOND+g7Brr58=";
          })
          (mkRaycast {
            name = "todo-list";
            rev = raycastRev;
            hash = "sha256-4HbJUGhB6Yz7t/lF/saAuCOZg+pYE9S6+t3i0yPMXuM=";
          })
          (mkRaycast {
            name = "spotify-player";
            rev = raycastRev;
            hash = "sha256-332DOAKVOnXkL/tLpQXlSPYl2fveAX46e9vfC7RoyVA=";
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
