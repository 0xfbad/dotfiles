_: {
  flake.modules.homeManager.claude-code = { pkgs, ... }: {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;

      settings = {
        model = "fable";
        includeCoAuthoredBy = false;
        disableArtifact = true;
        alwaysThinkingEnabled = true;
        promptSuggestionEnabled = true;
        skipDangerousModePermissionPrompt = true;
        switchModelsOnFlag = false;

        cleanupPeriodDays = 5;
        askUserQuestionTimeout = "5m";

        env = {
          # CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"; # good but disables /remote-control :(
          DISABLE_ERROR_REPORTING = "1";
          # since nix owns the package, kill background checks and claude update alike
          DISABLE_AUTOUPDATER = "1";
          DISABLE_UPDATES = "1";
          DISABLE_BUG_COMMAND = "1";
          # 15 is the hard cap, watchdog also retries capacity errors indefinitely
          CLAUDE_CODE_MAX_RETRIES = "15";
          CLAUDE_CODE_RETRY_WATCHDOG = "1";
        };

        permissions = {
          deny = [
            "Read(./.env)"
            "Read(./.env.*)"
            "Read(//home/fbad/.config/sops/age/**)"
            "Read(**/id_ed25519*)"
            "Read(**/*.pem)"
          ];
          defaultMode = "auto";
        };

        statusLine = {
          type = "command";
          command = "STARSHIP_CONFIG=\"$HOME/.config/starship-claude.toml\" starship statusline claude-code";
          padding = 0;
        };

        enabledPlugins."frontend-design@claude-plugins-official" = true;

        extraKnownMarketplaces.claude-code-plugins.source = {
          source = "github";
          repo = "anthropics/claude-code";
        };
      };

      context = ./CLAUDE.md;

      skills = ./skills;
    };
  };
}
