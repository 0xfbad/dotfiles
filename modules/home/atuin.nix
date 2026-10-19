_: {
  flake.modules.homeManager.atuin = _: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      daemon.enable = true;
      settings = {
        auto_sync = false;
        enter_accept = true;
        search_mode = "daemon-fuzzy";
        # every zellij pane is a fresh ATUIN_SESSION, plain session mode starts empty
        filter_mode_shell_up_key_binding = "session-preload";
        preview.strategy = "static";
        # config.toml is a readonly store symlink, the interactive ai prompt cannot persist a choice
        ai = {
          enabled = false;
          yolo = false;
        };
        history_filter = [
          "^claude"
          "^cc(\\s|$)"
          "\\.claude"
          "CLAUDE\\.md"
        ];
      };
    };

    catppuccin.atuin.enable = true;
  };
}
