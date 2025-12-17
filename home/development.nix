{ pkgs, ... }:

{
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
    zls
    zig

    # typescript/javascript
    typescript-language-server
    prettierd

    # docker
    docker
    dockerfile-language-server

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
    john
    pwntools
    binwalk

    # ai
    claude-code
  ];
}
