_: {
  flake.homeModules.atuin = _: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        update_check = false;
        enter_accept = true;
        style = "compact";
        show_preview = true;
        filter_mode_shell_up_key_binding = "session";
        history_filter = [
          "^claude"
          "^cc"
          "^opencode"
          "\\.claude"
          "CLAUDE\\.md"
        ];
      };
    };
  };
}
