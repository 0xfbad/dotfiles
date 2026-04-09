_: {
  flake.homeModules.btop = {
    pkgs,
    ...
  }: {
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
