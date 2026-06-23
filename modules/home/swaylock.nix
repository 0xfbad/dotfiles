_: {
  flake.homeModules.swaylock = {
    pkgs,
    lib,
    config,
    ...
  }: let
    c = config.colors;
    # remove prefix for swaylock
    h = lib.removePrefix "#";
  in {
    # pam service (security.pam.services.swaylock) is configured at the nixos level
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
      settings = {
        # blurred screenshot backdrop, downscaled first so the blur is fast
        screenshots = true;
        effect-scale = 0.4;
        effect-blur = "7x3";
        effect-vignette = "0.4:0.5";

        clock = true;
        timestr = "%H:%M";
        datestr = "%A, %d %B";
        font = "JetBrainsMono Nerd Font";
        font-size = 34;

        indicator = true;
        indicator-radius = 130;
        indicator-thickness = 15;
        indicator-caps-lock = true;

        ignore-empty-password = false;
        show-failed-attempts = true;

        inside-color = "000000cc";
        inside-clear-color = "000000cc";
        inside-ver-color = "000000cc";
        inside-wrong-color = "000000cc";

        ring-color = h c.pink;
        ring-clear-color = h c.flamingo;
        ring-ver-color = h c.accent;
        ring-wrong-color = h c.red;

        key-hl-color = h c.bg;
        bs-hl-color = h c.bg;

        text-color = h c.pink;
        text-clear-color = h c.flamingo;
        text-ver-color = h c.accent;
        text-wrong-color = h c.red;
        text-caps-lock-color = h c.pink;

        line-color = "00000000";
        line-clear-color = "00000000";
        line-ver-color = "00000000";
        line-wrong-color = "00000000";
        separator-color = "00000000";
      };
    };
  };
}
