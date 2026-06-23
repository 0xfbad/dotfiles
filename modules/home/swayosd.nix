_: {
  flake.homeModules.swayosd = {config, ...}: {
    # swayosd-server runs as a graphical-session user service via this module
    # not covered by catppuccin/nix, so theme it by hand
    services.swayosd.enable = true;

    # swayosd-server auto-loads this path on start
    xdg.configFile."swayosd/style.css".text = ''
      window {
        background: ${config.colors.bg};
        border: 2px solid ${config.colors.accent};
        border-radius: ${toString config.colors.rounding}px;
        padding: 12px;
      }

      label {
        color: ${config.colors.text};
      }

      image {
        color: ${config.colors.text};
      }

      progressbar {
        border-radius: ${toString config.colors.rounding}px;
      }

      progressbar trough {
        background: ${config.colors.surface0};
        border-radius: ${toString config.colors.rounding}px;
        min-height: 8px;
      }

      progressbar progress {
        background: ${config.colors.accent};
        border-radius: ${toString config.colors.rounding}px;
        min-height: 8px;
      }
    '';
  };
}
