_: {
  flake.homeModules.atuin = _: {
    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        update_check = false;
        enter_accept = true;
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
