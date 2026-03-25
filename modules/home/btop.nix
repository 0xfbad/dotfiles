_: {
  flake.homeModules.btop = _: {
    programs.btop = {
      enable = true;
      settings.color_theme = "catppuccin_mocha";
    };
  };
}
