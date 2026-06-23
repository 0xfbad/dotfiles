_: {
  flake.homeModules.mako = {config, ...}: {
    # colors themed globally by catppuccin/nix
    services.mako = {
      enable = true;
      settings = {
        default-timeout = 5000;
        border-radius = config.colors.rounding;
        width = 360;
        height = 120;
        margin = 12;
        padding = 12;
        icons = true;
        max-icon-size = 48;
        anchor = "top-right";
        layer = "overlay";
      };
    };
  };
}
