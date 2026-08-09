_: {
  flake.modules.homeManager.development = { pkgs, ... }: {
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

      opencode.enable = true;
      nix-search-tv.enable = true;
    };

    home.packages = with pkgs; [
      # python
      # pwntools is toPythonApplication, so it only imports from an interpreter env
      (python3.withPackages (ps: with ps; [ pwntools ]))
      ty # python type checker from the ruff team
      ruff

      # rust
      cargo # rust-analyzer shells out to it for workspace metadata
      rustc
      rustfmt

      # go
      gotools # goimports, godoc
      delve # go debugger

      # zig
      zig

      # javascript and typescript
      prettierd

      # networking
      cloudflared

      # shell
      shfmt

      # nix
      nix-inspect
      nix-tree # browse a closure interactively, find what pulls a dependency in
      statix # nix linter, suggests antipattern fixes
      deadnix # finds unused let bindings and function arguments
      nixfmt # the rfc 166 style treefmt runs
      manix # searches nixos and home-manager docs from the cli

      # typst
      typst

      # security and secret scanning
      trufflehog # scans git repos for leaked secrets, tests if they are still live
      gitleaks # lighter secret scanner for git history, good for pre-commit hooks
      age
      sops # encrypts values but leaves yaml and json keys readable for diffs

      # security and pentesting
      nmap
      strace
      feroxbuster # web directory bruteforcer
      burpsuite # web application testing proxy
      ghidra
      gdb
      gef # exploit dev helpers on top of gdb
      imhex # hex editor with a pattern language
      exploitdb # searchsploit, offline exploit database
      # wfuzz # TEMP dropped bc fails on missing pkg_resources under python 3.14
      (wordlists.override {
        lists = [
          nmap
          rockyou
          seclists
        ];
      })
      crunch # wordlist generator
      john # password cracker
      pwninit # patches a downloaded challenge binary against its libc, writes a solve template
      pwncat # post exploitation shell handler
      binwalk # firmware analysis, finds embedded files and filesystems
      xxd
      expect # automates interactive cli programs

      # monitoring
      glances # system monitor like htop with more detail

      # parser tools
      tree-sitter
      ast-grep # structural search and replace via tree-sitter
      scooter # find and replace tui, toggle individual replacements, helix integration

      # benchmarking and analysis
      hyperfine # benchmarks cli commands
      tokei # code stats by language, faster than cloc

      # http testing
      hurl # http request runner driven by plain text files
      # harlequin # tui SQL editor TEMP DISABLED bc a sqlfmt dependency fails pythonMetadataCheck under python 3.14
    ];
  };
}
