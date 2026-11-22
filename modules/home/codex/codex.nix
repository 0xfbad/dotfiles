_: {
  flake.modules.homeManager.codex =
    { config, ... }:
    let
      dots = "${config.home.homeDirectory}/dotfiles";
      cc = "${dots}/modules/home/claude-code";
    in
    {
      home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${cc}/CLAUDE.md";
      home.file.".agents/skills".source = config.lib.file.mkOutOfStoreSymlink "${cc}/skills";

      programs.codex = {
        enable = true;
        mutableSettings = true; # the tui and t3 also write config.toml

        settings = {
          check_for_update_on_startup = false;
          analytics.enabled = false;
          feedback.enabled = false;
          approvals_reviewer = "auto_review";
          shell_environment_policy.set = import ../claude-code/_agent-git-env.nix "${cc}/hooks/agent_git.py";
        };

        hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "${cc}/hooks/git-guard.sh"; # hooks require approval in the tui with /hooks
              }
            ];
          }
        ];

        hooks.PostToolUse = [
          {
            matcher = "^(apply_patch|Edit|Write)$";
            hooks = [
              {
                type = "command";
                command = "${cc}/hooks/comment-guard.py";
                timeout = 10;
              }
            ];
          }
        ];
      };
    };
}
