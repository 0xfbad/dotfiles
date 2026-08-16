_: {
  flake.modules.homeManager.atuin = { config, ... }: {
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
        theme.name = "catppuccin-mocha-mauve";
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

    # catppuccin.atuin.enable reads <src>/themes/mocha/, the packaged port ships mocha/ at the root
    xdg.configFile."atuin/themes/catppuccin-mocha-mauve.toml".source =
      "${config.catppuccin.sources.atuin}/mocha/catppuccin-mocha-mauve.toml";
  };
}
