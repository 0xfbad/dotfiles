_: {
  flake.homeModules.hyprlock = {config, ...}: let
    c = config.colors.hypr;
  in {
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 5;
          ignore_empty_input = true;
        };

        background = [
          {
            monitor = "";
            color = c.bg;
            blur_passes = 2;
            blur_size = 4;
          }
        ];

        input-field = [
          {
            monitor = "";
            size = "300, 50";
            outline_thickness = 2;
            outer_color = c.accent;
            inner_color = c.mantle;
            font_color = c.text;
            fade_on_empty = true;
            placeholder_text = "";
            dots_center = true;
            dots_size = 0.25;
            dots_spacing = 0.2;
            rounding = 0;
            halign = "center";
            valign = "center";
            position = "0, -50";
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            color = c.accent;
            font_size = 72;
            font_family = "JetBrainsMono Nerd Font";
            halign = "center";
            valign = "center";
            position = "0, 100";
          }
        ];
      };
    };
  };
}
