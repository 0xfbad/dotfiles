_: {
  flake.modules.homeManager.hyprlock =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.colors;
      h = lib.removePrefix "#";
      rgb = color: "rgb(${h color})";
      rgba = color: alpha: "rgba(${h color}${alpha})";

      font = "JetBrainsMono Nerd Font";
      date = lib.getExe' pkgs.coreutils "date";
    in
    {
      # auth:pam:module is hyprlock, the nixos side must declare security.pam.services.hyprlock
      programs.hyprlock = {
        enable = true;
        settings = {
          general.hide_cursor = true;

          background = [
            {
              monitor = "";
              path = "screenshot";
              # painted when screencopy fails, so a broken grab stays black
              color = rgb c.bg;
              blur_passes = 3;
              blur_size = 8;
              brightness = 0.5;
              vibrancy = 0.1;
            }
          ];

          input-field = [
            {
              monitor = "";
              size = "360, 60";
              position = "0, 0";
              halign = "center";
              valign = "center";

              outline_thickness = 3;
              inherit (c) rounding;
              inner_color = rgba c.bg "cc";
              outer_color = rgb c.pink;
              check_color = rgb c.accent;
              fail_color = rgb c.red;
              capslock_color = rgb c.peach;

              font_family = font;
              font_color = rgb c.text;
              placeholder_text = "<i>Password</i>";
              fail_text = "$FAIL ($ATTEMPTS)";

              dots_center = true;
              dots_spacing = 0.3;
              fade_on_empty = false;
            }
          ];

          label = [
            {
              monitor = "";
              text = "$TIME";
              font_family = font;
              font_size = 90;
              color = rgb c.text;
              position = "0, 160";
              halign = "center";
              valign = "center";
            }
            {
              monitor = "";
              text = ''cmd[update:60000] ${date} +"%A, %d %B"'';
              font_family = font;
              font_size = 22;
              color = rgb c.subtext0;
              position = "0, 90";
              halign = "center";
              valign = "center";
            }
          ];
        };
      };
    };
}
