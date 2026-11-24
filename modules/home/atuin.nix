_: {
  flake.modules.homeManager.atuin = _: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      daemon.enable = true;
      settings = {
        auto_sync = false;
        update_check = false;
        enter_accept = true;
        search_mode = "daemon-fuzzy";
        # each zellij pane is a new ATUIN_SESSION, plain session starts empty
        filter_mode_shell_up_key_binding = "session-preload";
        preview.strategy = "static";
        # unset, the ai keybind prompts on every use since config.toml is a read only store symlink
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
