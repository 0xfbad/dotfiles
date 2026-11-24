_: {
  flake.modules.homeManager.development = { pkgs, ... }: {
    home.sessionVariables = {
      ASTRO_TELEMETRY_DISABLED = "1";
      DOTNET_CLI_TELEMETRY_OPTOUT = "1";
      LANGSMITH_TRACING = "false";
      LANGSMITH_TRACING_V2 = "false";
      NEXT_TELEMETRY_DISABLED = "1";
      POWERSHELL_TELEMETRY_OPTOUT = "1";
      WANDB_MODE = "disabled";
    };

    programs = {
      direnv = {
        enable = true;
        silent = true;
        nix-direnv.enable = true;
      };

      go = {
        enable = true;
        telemetry.mode = "off";
      };

      nix-search-tv.enable = true;
    };

    home.packages = with pkgs; [
      (python3.withPackages (ps: with ps; [ pwntools ])) # pkgs.pwntools is toPythonApplication, not importable
      ty # python type checker from the ruff team
      ruff

      cargo # rust-analyzer shells out to it for workspace metadata
      rustc
      rustfmt

      gotools # goimports, stringer, modernize
      delve # go debugger

      zig

      prettierd

      cloudflared

      shfmt

      nix-inspect
      nix-tree # browse a closure interactively, find what pulls a dependency in
      statix # nix linter, suggests antipattern fixes
      deadnix # finds unused let bindings and function arguments
      nixfmt # the rfc 166 style treefmt runs
      manix # searches nixos and home-manager docs from the cli

      typst

      trufflehog # scans git repos for leaked secrets, tests if they are still live
      gitleaks # scans git history and staged changes for secrets
      age
      sops # encrypts values, leaves yaml and json keys readable

      nmap
      strace
      gdb
      gef # exploit dev helpers on top of gdb
      imhex # hex editor with a pattern language
      binwalk # firmware analysis, finds embedded files and filesystems
      xxd
      expect # automates interactive cli programs

      tree-sitter
      ast-grep # structural search and replace via tree-sitter
      scooter # find and replace tui, toggle individual replacements, helix integration

      hyperfine # benchmarks cli commands
      tokei # code stats by language

      hurl # http request runner driven by plain text files
      harlequin # tui sql editor
    ];
  };
}
