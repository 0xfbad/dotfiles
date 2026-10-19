_: {
  flake.modules.homeManager.mako =
    { config, ... }:
    let
      c = config.colors;
    in
    {
      # the catppuccin port hardcodes #1e1e2e and its include= clobbers earlier keys
      services.mako = {
        enable = true;
        settings = {
          background-color = c.bg;
          text-color = c.text;
          border-color = c.accent;
          progress-color = "over ${c.surface0}";

          border-radius = c.rounding;
          icon-border-radius = 6;
          width = 360;
          height = 120;
          margin = 12;
          padding = 12;
          max-icon-size = 48;
          layer = "overlay";

          default-timeout = 5000;
          group-by = "app-name";
          on-button-right = "dismiss-all";

          "urgency=critical" = {
            border-color = c.red;
            default-timeout = 0;
          };

          # hyprlock.service in hypridle.nix toggles this mode
          "mode=lock".invisible = 1;
          "mode=do-not-disturb".invisible = 1;
        };
      };
    };
}
