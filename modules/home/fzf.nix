_: {
  flake.modules.homeManager.fzf = _: {
    programs.fzf = {
      enable = true;
      defaultCommand = "fd --type f --hidden --exclude .git";
      # colors come from the catppuccin FZF_DEFAULT_OPTS_FILE
      defaultOptions = [
        "--layout=reverse"
        "--border=rounded"
        "--height=40%"
        # needs zellij 0.44, ignored outside a multiplexer
        "--popup=80%,70%"
      ];
      fileWidget = {
        command = "fd --type f --hidden --exclude .git";
        options = [ "--preview 'bat --color=always --style=numbers --line-range=:200 {}'" ];
      };
      changeDirWidget = {
        command = "fd --type d --hidden --exclude .git";
        options = [ "--preview 'eza --tree --color=always --level=2 {}'" ];
      };
      # atuin owns ctrl-r
      historyWidget.command = "";
    };
  };
}
