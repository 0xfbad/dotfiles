_: {
  flake.modules.homeManager.codex =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      dots = "${config.home.homeDirectory}/dotfiles";
      cc = "${dots}/modules/home/claude-code";

      settings = pkgs.writeText "codex-settings.json" (builtins.toJSON config.codex.settings);
      python = pkgs.python3.withPackages (p: [ p.tomlkit ]);
      mergeSettings = pkgs.writeScript "merge-codex-settings" ''
        #!${python}/bin/python3
        import json
        import os
        from pathlib import Path
        import tempfile
        import tomlkit

        def merge(destination, source):
            for key, value in source.items():
                if not isinstance(value, dict):
                    destination[key] = value
                    continue

                if key not in destination:
                    destination[key] = tomlkit.table()
                merge(destination[key], value)

        target = Path(${builtins.toJSON "${config.home.homeDirectory}/.codex/config.toml"})  # the tui and t3 also write config.toml
        target.parent.mkdir(parents=True, exist_ok=True)
        document = tomlkit.parse(target.read_text()) if target.exists() else tomlkit.document()
        settings = json.loads(Path("${settings}").read_text())
        merge(document, settings)
        contents = tomlkit.dumps(document)
        if target.exists() and target.read_text() == contents:
            raise SystemExit(0)

        fd, temporary = tempfile.mkstemp(dir=target.parent, prefix="config.toml.")
        try:
            with os.fdopen(fd, "w") as output:
                output.write(contents)
            os.replace(temporary, target)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
      '';
    in
    {
      options.codex.settings = lib.mkOption {
        inherit ((pkgs.formats.toml { })) type;
        default = { };
      };

      config = {
        codex.settings = {
          check_for_update_on_startup = false;
          analytics.enabled = false;
          feedback.enabled = false;
          personality = "pragmatic";
          approvals_reviewer = "auto_review";
        };

        home.activation.codexSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${mergeSettings}
        '';

        home.file.".codex/AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${cc}/CLAUDE.md";
        home.file.".codex/skills/cleanup".source =
          config.lib.file.mkOutOfStoreSymlink "${cc}/skills/cleanup";
        home.file.".codex/skills/complexity-review".source =
          config.lib.file.mkOutOfStoreSymlink "${cc}/skills/complexity-review";

        programs.codex = {
          enable = true;
          package = pkgs.codex;

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
    };
}
