_: {
  flake.homeModules.mako = {config, ...}: let
    c = config.colors;
  in {
    services.mako = {
      enable = true;
      settings = {
        anchor = "top-right";
        default-timeout = 5000;
        border-radius = 8;
        border-size = 2;
        padding = "12";
        margin = "10";
        width = 350;
        background-color = c.bgAlpha;
        text-color = c.text;
        border-color = c.accent;
        progress-color = "over ${c.surface0}";
        font = "JetBrainsMono Nerd Font 10";
        layer = "overlay";
      };
    };
  };
}
