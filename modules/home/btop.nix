_: {
  flake.homeModules.btop = {pkgs, ...}: {
    # catppuccin mocha with oled black background
    xdg.configFile."btop/themes/catppuccin_mocha.theme".text = builtins.replaceStrings
      [''theme[main_bg]="#1e1e2e"'']
      [''theme[main_bg]="#000000"'']
      (builtins.readFile (builtins.fetchurl {
        url = "https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme";
        sha256 = "0i263xwkkv8zgr71w13dnq6cv10bkiya7b06yqgjqa6skfmnjx2c";
      }));

    programs.btop = {
      enable = true;
      package = pkgs.btop.override {cudaSupport = true;};
      settings = {
        color_theme = "catppuccin_mocha";
        shown_boxes = "cpu mem net proc gpu0";
        vim_keys = true;
        update_ms = 200;
        truecolor = true;
      };
    };
  };
}
