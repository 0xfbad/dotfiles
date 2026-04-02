_: {
  flake.homeModules.zellij = _: {
    programs.zellij = {
      enable = true;
      settings = {
        theme = "catppuccin-mocha";
        default_layout = "compact";
        show_startup_tips = false;
        copy_on_select = true;
        pane_frames = false;
        # scrollback opens in helix
        scrollback_editor = "hx";
      };
    };
  };
}
