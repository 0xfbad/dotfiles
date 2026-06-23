_: {
  flake.homeModules.colors = {lib, ...}: {
    # catppuccin mocha palette with OLED black override
    # every module should reference these instead of hardcoding hex values
    options.colors = lib.mkOption {
      type = lib.types.attrs;
      default = {
        bg = "#000000";
        bgAlpha = "#000000ee";
        bgAlphaHigh = "#000000e6";
        mantle = "#181825";
        surface0 = "#313244";
        surface1 = "#6c7086";
        subtext0 = "#a6adc8";
        text = "#cdd6f4";
        accent = "#cba6f7";
        red = "#f38ba8";
        blue = "#89b4fa";
        peach = "#fab387";
        green = "#a6e3a1";
        yellow = "#f9e2af";
        pink = "#f5c2e7";
        flamingo = "#f2cdcd";
        rosewater = "#f5e0dc";
        sky = "#89dceb";
        sapphire = "#74c7ec";
        lavender = "#b4befe";
        teal = "#94e2d5";

        rounding = 12;
      };
    };
  };
}
