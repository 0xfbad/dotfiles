{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    # version control
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
    gotools
    delve

    # zig
    # zls  # broken in nixpkgs
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
    # john brokey
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
}
