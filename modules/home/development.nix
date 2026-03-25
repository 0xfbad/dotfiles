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

      # ai
      claude-code
      opencode

      # ide for notebooks
      jetbrains.pycharm
    ];
  };
}
