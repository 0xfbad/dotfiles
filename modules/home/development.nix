_: {
  flake.homeModules.development = {
    pkgs,
    lib,
    ...
  }: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    home.packages = with pkgs; [
      # version control
      gh
      gitui
      difftastic # modern git diff, parses ASTs via tree-sitter, shows semantic changes

      # python
      python314
      ty
      ruff

      # rust
      rust-analyzer
      rustfmt

      # go
      gopls
      # lowPrio because gotools ships an older lib that conflicts with sox
      (lib.lowPrio gotools)
      delve

      # zig
      zls
      zig

      # typescript/javascript
      typescript-language-server
      prettierd

      # docker
      docker
      dockerfile-language-server
      virtiofsd
      cloudflared

      # database
      mongodb-compass

      # shell
      bash-language-server
      shfmt

      # nix
      nil
      nixd
      nix-inspect
      statix
      alejandra
      manix

      # typst
      typst
      tinymist

      # security and secret scanning
      trufflehog # scans git repos for leaked secrets, tests if they're still live
      gitleaks # lighter secret scanner for git history, good for pre-commit hooks
      age # modern GPG replacement, no keyrings, just encrypts files, SSH keys
      sops # encrypts values in YAML/JSON but leaves keys readable for diffs

      # security and pentesting
      nmap
      wireshark
      strace
      feroxbuster
      burpsuite
      ghidra
      gdb
      gef
      imhex
      exploitdb
      wordlists
      crunch
      john
      pwntools
      binwalk
      glances
      xxd
      expect

      # prose
      harper

      # hyprland
      hyprls

      # parser tools
      tree-sitter
      ast-grep # structural search/replace via tree-sitter, match code by pattern
      scooter # interactive find-and-replace TUI, toggle individual replacements, helix integration

      # benchmarking and analysis
      hyperfine # benchmarks CLI commands, warmup runs, confidence intervals
      tokei # code stats by language (lines, blanks, comments), faster than cloc

      # http testing
      hurl # HTTP request runner using plain text files, chain requests, assert responses
      harlequin # SQL IDE in terminal, autocomplete, highlighting, Postgres/DuckDB/SQLite

      # ai
      claude-code
      opencode
      mods # charm's LLM pipe tool, cat log | mods "what's wrong", works with any provider

      # ide for notebooks
      jetbrains.pycharm
    ];
  };
}
