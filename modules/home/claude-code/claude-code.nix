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
            --anchored --no-wildcards-match-slash --exclude=skills/synced --exclude='skills/*-workspace' --exclude='skills/.*' \
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
          findutils
        ];
        text = ''
          cd ${dots}
          t=$(mktemp)
          trap 'rm -f "$t"' EXIT
          age -d -i ${key} -o "$t" secrets/prompts.age
          mkdir -p modules/home/claude-code/skills
          find modules/home/claude-code/skills -mindepth 1 -maxdepth 1 ! -name synced ! -name '*-workspace' ! -name '.*' -exec rm -rf {} +
          tar -xpf "$t" -C modules/home/claude-code
        '';
      };
    in
    {
      home.packages = [ prompts-pack ];

      home.activation.promptsSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${pkgs.git}/bin/git -C ${dots} config core.hooksPath .githooks
        cc=${dots}/modules/home/claude-code
        if [ -f ${dots}/secrets/prompts.age ]; then
          if [ ! -e "$cc/skills" ] || [ -z "$(${pkgs.findutils}/bin/find "$cc/skills" "$cc/hooks" "$cc/CLAUDE.md" \( -path "$cc/skills/synced" -o \( -path "$cc/skills/*-workspace" -o -path "$cc/skills/.*" \) ! -path "$cc/skills/*/*" \) -prune -o -newer ${dots}/secrets/prompts.age -print -quit 2>/dev/null)" ]; then
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

        settings = {
          model = "fable";
          outputStyle = "Concise";
          tui = "fullscreen";
          enableArtifact = false;
          promptSuggestionEnabled = true;
          skipDangerousModePermissionPrompt = true;
          switchModelsOnFlag = false;
          remoteControlAtStartup = false;
          syncClaudeAiSkills = false;

          cleanupPeriodDays = 5;
          askUserQuestionTimeout = "5m";

          attribution = {
            commit = "";
            pr = "";
            sessionUrl = false;
          };

          env = {
            # no CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC, it disables /remote-control
            DISABLE_ERROR_REPORTING = "1";
            DISABLE_UPDATES = "1";
            DISABLE_FEEDBACK_COMMAND = "1";
            CLAUDE_CODE_RETRY_WATCHDOG = "1";
            CLAUDE_CODE_EXPERIMENTAL_CODE_MODE = "1";
          };

          enabledMcpjsonServers = [ "canvas" ];

          permissions = {
            ask = [
              "mcp__canvas__delete_*"
              "mcp__canvas__remove_group_member"
            ];
            deny = [
              "Read(./.env)"
              "Read(./.env.*)"
              "Read(~/.config/sops/age/**)"
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
