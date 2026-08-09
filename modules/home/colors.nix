_: {
  flake.modules.homeManager.colors =
    { lib, ... }:
    let
      # catppuccin mocha, base swapped for true black on the OLED panel
      palette = {
        bg = "#000000";
        base = "#1e1e2e";
        mantle = "#181825";
        crust = "#11111b";
        surface0 = "#313244";
        surface1 = "#45475a";
        surface2 = "#585b70";
        overlay0 = "#6c7086";
        overlay1 = "#7f849c";
        overlay2 = "#9399b2";
        subtext0 = "#a6adc8";
        subtext1 = "#bac2de";
        text = "#cdd6f4";
        accent = "#cba6f7";
        rosewater = "#f5e0dc";
        flamingo = "#f2cdcd";
        pink = "#f5c2e7";
        red = "#f38ba8";
        maroon = "#eba0ac";
        peach = "#fab387";
        yellow = "#f9e2af";
        green = "#a6e3a1";
        teal = "#94e2d5";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        blue = "#89b4fa";
        lavender = "#b4befe";
      };
    in
    {
      options.colors = lib.mkOption {
        description = ''
          Catppuccin mocha palette with an OLED black base. Modules should
          reference these instead of hardcoding hex values.
        '';
        default = { };
        # one option per key so a host can override a single color without wiping the rest
        type = lib.types.submodule {
          options =
            lib.mapAttrs (
              _: hex:
              lib.mkOption {
                type = lib.types.strMatching "#[0-9a-fA-F]{6,8}";
                default = hex;
              }
            ) palette
            // {
              rounding = lib.mkOption {
                type = lib.types.ints.unsigned;
                default = 12;
              };
            };
        };
      };
    };
}
