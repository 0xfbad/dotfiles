_: {
  flake.modules.homeManager.codex =
    { config, ... }:
    let
      dots = "${config.home.homeDirectory}/dotfiles";
      cc = "${dots}/modules/home/claude-code";
    in
    {
      home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${cc}/CLAUDE.md";
      home.file.".codex/skills/cleanup".source =
        config.lib.file.mkOutOfStoreSymlink "${cc}/skills/cleanup";
      home.file.".codex/skills/complexity-review".source =
        config.lib.file.mkOutOfStoreSymlink "${cc}/skills/complexity-review";

      programs.codex = {
        enable = true;
        mutableSettings = true; # the tui and t3 also write config.toml

        settings = {
          check_for_update_on_startup = false;
          analytics.enabled = false;
          feedback.enabled = false;
          approvals_reviewer = "auto_review";
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
      };
    };
}
