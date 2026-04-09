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
      # python
      python3 # follows nixpkgs default Python version
      ty # Python type checker by Astral (ruff team)
      ruff # fast Python linter and formatter

      # rust
      rust-analyzer # Rust LSP
      rustfmt # Rust code formatter

      # go
      gopls # Go LSP
      # lowPrio because gotools ships an older lib that conflicts with sox
      (lib.lowPrio gotools) # extra Go dev tools (goimports, godoc)
      delve # Go debugger

      # zig
      zls # Zig LSP
      zig # Zig compiler

      # typescript/javascript
      typescript-language-server # TypeScript/JavaScript LSP
      prettierd # daemon mode Prettier for fast formatting

      # docker
      docker # container runtime
      dockerfile-language-server # Dockerfile LSP
      virtiofsd # virtio filesystem daemon for VM shared folders
      cloudflared # Cloudflare tunnel client

      # database
      mongodb-compass # MongoDB GUI

      # shell
      bash-language-server # Bash LSP
      shfmt # shell script formatter

      # nix
      nil # Nix LSP
      nixd # Nix LSP with nixpkgs evaluation support
      nix-inspect # inspect nix derivation details interactively
      statix # nix linter, suggests anti-pattern fixes
      alejandra # nix formatter, opinionated
      manix # search NixOS/home-manager options and docs from CLI

      # typst
      typst # modern LaTeX alternative, fast compilation
      tinymist # Typst LSP

      # security and secret scanning
      trufflehog # scans git repos for leaked secrets, tests if they're still live
      gitleaks # lighter secret scanner for git history, good for pre-commit hooks
      age # modern GPG replacement, no keyrings, just encrypts files, SSH keys
      sops # encrypts values in YAML/JSON but leaves keys readable for diffs

      # security and pentesting
      nmap # network scanner, port/service discovery
      strace # trace system calls for debugging
      feroxbuster # web directory/content brute-forcer
      burpsuite # web application security testing proxy
      ghidra # NSA's reverse engineering tool, disassembler/decompiler
      gdb # GNU debugger
      gef # GDB Enhanced Features, exploit dev helpers on top of gdb
      imhex # hex editor with pattern language and analysis tools
      exploitdb # offline exploit database search (searchsploit)
      wordlists # password/fuzzing wordlists (rockyou, dirb, etc)
      crunch # custom wordlist generator
      john # John the Ripper password cracker
      pwntools # CTF/exploit dev framework for Python
      binwalk # firmware analysis, finds embedded files and filesystems
      glances # system monitor like htop with more detail
      xxd # hex dump and reverse hex dump
      expect # automate interactive CLI programs

      # prose
      harper # grammar checker LSP, works in any editor

      # hyprland
      hyprls # Hyprland config LSP

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
      claude-code # Anthropic's slopmachine
      opencode # open-source slopmachine

      # ide for notebooks
      jetbrains.pycharm # Python IDE
    ];
  };
}
