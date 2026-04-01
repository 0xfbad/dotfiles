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

        # hyprland uses rgb() without # prefix
        hypr = {
          bg = "rgb(000000)";
          mantle = "rgb(181825)";
          surface0 = "rgb(313244)";
          text = "rgb(cdd6f4)";
          accent = "rgb(cba6f7)";
        };
      };
    };
  };
}
