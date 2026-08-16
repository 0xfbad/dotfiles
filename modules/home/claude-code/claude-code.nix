_: {
  flake.modules.homeManager.claude-code =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      dots = "${config.home.homeDirectory}/dotfiles";
      key = "${config.xdg.configHome}/sops/age/keys.txt";

      prompts-pack = pkgs.writeShellApplication {
        name = "prompts-pack";
        runtimeInputs = with pkgs; [
          age
          gnutar
          diffutils
        ];
        text = ''
          cd ${dots}
          t=$(mktemp)
          trap 'rm -f "$t"' EXIT
          tar --sort=name --owner=0 --group=0 --numeric-owner --mtime=@0 \
            -C modules/home/claude-code -cf "$t" skills hooks CLAUDE.md
          if [ -f secrets/prompts.age ] && age -d -i ${key} secrets/prompts.age 2>/dev/null | cmp -s - "$t"; then
            echo unchanged
          else
            age -R secrets/api.recipients -o secrets/prompts.age "$t"
            echo packed
          fi
        '';
      };

      prompts-unpack = pkgs.writeShellApplication {
        name = "prompts-unpack";
        runtimeInputs = with pkgs; [
          age
          gnutar
        ];
        text = ''
          cd ${dots}
          age -d -i ${key} secrets/prompts.age | tar -xpf - -C modules/home/claude-code
        '';
      };
    in
    {
      home.packages = [ prompts-pack ];

      home.activation.promptsSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.git}/bin/git -C ${dots} config core.hooksPath .githooks
        cc=${dots}/modules/home/claude-code
        # skip when local plaintext is newer
        if [ -f ${dots}/secrets/prompts.age ]; then
          if [ ! -e "$cc/skills" ] || [ -z "$(${pkgs.findutils}/bin/find "$cc/skills" "$cc/hooks" "$cc/CLAUDE.md" -newer ${dots}/secrets/prompts.age -print -quit 2>/dev/null)" ]; then
            run ${lib.getExe prompts-unpack} || verboseEcho "prompts unpack failed"
          fi
        fi
      '';

      home.file.".claude/CLAUDE.md".source =
        config.lib.file.mkOutOfStoreSymlink "${dots}/modules/home/claude-code/CLAUDE.md";
      home.file.".claude/skills".source =
        config.lib.file.mkOutOfStoreSymlink "${dots}/modules/home/claude-code/skills";

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

          attribution = {
            commit = "";
            pr = "";
          };

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

          hooks.PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "${config.home.homeDirectory}/dotfiles/modules/home/claude-code/hooks/git-guard.sh";
                }
              ];
            }
          ];
        };
      };
    };
}
