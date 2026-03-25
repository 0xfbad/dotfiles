# dotfiles

Personal dotfiles for NixOS and every other hipster riced app I use via home-manager. Following the [dendritic pattern](https://vimjoyer.dev/p/organizing-nix-config/) from vimjoyer's video, everything in `modules/` gets auto-discovered by flake-parts + import-tree so you never have to manually wire imports in the flake

## layout

```
flake.nix
modules/
  flake-parts.nix
  formatting.nix              treefmt, alejandra, statix
  hosts/
    desktop/                   RTX 3090, dual monitor, GRUB (because i dont fucking know what happened to efi), intel cpu
    laptop/                    Discrete RTX 4090, systemd-boot, LUKS, intel cpu
  features/
    hyprland.nix               compositor, keybinds, wallpaper
    noctalia.nix               bar, notifications, launcher, clipboard
    greetd.nix                 tuigreet + uwsm
    common.nix                 nix settings, locale, bluetooth, user
    nvidia.nix                 GPU drivers, wayland session vars
    audio.nix                  pipewire
    virtualization.nix         docker, libvirt, qemu
    anonymity.nix              tor, dnscrypt
    networking.nix             networkmanager, dns
    flatpak.nix                flatpak, sober
    determinate.nix            determinate nix
  home/
    default.nix                home-manager wiring
    terminal.nix               packages (cli utils, compression, networking)
    desktop.nix                packages (browsers, media, comms, gaming)
    development.nix            packages (LSPs, dev tools, security), direnv
    helix.nix                  editor config, nixd + nil
    firefox.nix                declarative profile, search engines, privacy
    zsh.nix                    shell, aliases, functions
    wezterm.nix                terminal emulator
    atuin.nix                  shell history
    bat.nix                    cat replacement + extras
    eza.nix                    ls replacement + theme
    yazi.nix                   file manager + catppuccin
    gitui.nix                  git TUI + theme
    zellij.nix                 multiplexer
    starship.nix               prompt
    zoxide.nix                 smart cd
    btop.nix                   system monitor
    tealdeer.nix               tldr
    mangohud.nix               gaming overlay
    jujutsu.nix                modern VCS
    zed.nix                    gui editor, minimal + no telemetry
    pycharm.nix                jetbrains
```

## stealing this

Take whatever you want. Clone to `~/dotfiles` on a bare NixOS system and go through the stuff you need to change

I'm `fbad` in a bunch of places (user def in `modules/features/common.nix`, home-manager in `modules/home/default.nix`, probably others). Grep for it, swap in yours

Copy a host dir to your own name, replace the hardware config with `nixos-generate-config --show-hardware-config` output. Hostname in `configuration.nix` matches the directory. Set your bootloader, kernel modules, whatever. The `default.nix` registers the host as `flake.nixosConfigurations.yourhostname`, just copy desktop's and change the name

Features are all optional, just import the ones you want in your host's `configuration.nix`

`nh os switch` and pray (or `sudo nixos-rebuild switch --flake ~/dotfiles#yourhostname` if you haven't set up nh yet)

## cool stuff about this setup

- DNS over HTTPS via dnscrypt-proxy (no local or ISP snooping)
- OLEDmaxxing theme, everything is fully black
- Hyprland with no gaps because i paid for my pixels and im going to use all of them
- Noctalia bar with animations off for snappy response
- Wezterm + zellij (basically better tmux, sane config, built-in layouts)
- Yazi for file browsing (more modern ranger with image previews)
- Helix with LSPs for like 10 languages, nixd for NixOS/home-manager option completion
- Atuin for shell history (searchable, syncs across machines if you want)
- Zoxide instead of cd (learns your frequent dirs, `cd foo` jumps to ~/whatever/foo)
- Starship prompt
- Bat instead of cat (syntax highlighting, git diff integration, batman for man pages)
- Eza instead of ls (icons, git status, tree view)
- Dust instead of du (visual disk usage bars, sorted by size)
- Greetd login with system specs on screen (CPU, RAM, GPU, disk, IP)
- Keybind cheat sheet popup on Super + Shift + ? via rofi
- wlr-which-key on Super + D for quick actions (screenshots, recording, volume mixer, file manager)
- Live wallpaper through mpvpaper
- Bibata cursor theme
- Catppuccin mocha on everything that supports it (btop, gitui, yazi, helix, wezterm, zed, eza, bat)
- Cowsay greeting that changes based on time of day
- Some shell functions for quickly optimizing videos and images (`optimize-video`, `optimize-image`)
- My more used cyber tools (nmap, burpsuite, ghidra, gdb+gef, pwntools, binwalk, imhex, etc)
- Claude Code and opencode for slopmaxxing
- Tealdeer for tldr pages
- Comma via nix-index-database (i.e. `, supertuxkart` instead of `nix shell nixpkgs#supertuxkart`)
- nh for nixos rebuilds, shows you a diff of what's changing before it applies
- nix-ld so you can run random binaries without the "interpreter not found" song and dance
- Jujutsu (jj) alongside git, modern VCS with undo, auto-commit working copy, colocated with git repos
- Ripdrag for dragging files out of the terminal into GUI apps
- Declarative Firefox with extensions force-installed (uBlock, Bitwarden, Dark Reader, Tampermonkey, Unhook, etc), all telemetry/AI/pocket/sponsored slop nuked, OLED black userChrome, custom search engines (`@np` nix packages, `@no` nixos options, `@nw` wiki, `@hm` home-manager)
- Zed as a gui editor for when you don't want a terminal, stripped down with all the networking/AI/collab stuff off
- Nautilus for when you need a gui file manager
- sshfs for mounting remote dirs over SSH
- Gaming stack: proton-ge, gamescope, gamemode, mangohud overlay. `gamemoderun mangohud %command%` in steam launch options

## aliases

- `rebuild` - nh os switch (shows diff before applying)
- `update` - nh os switch -u (updates flake lock then rebuilds)
- `gc` - nh clean all (keeps 3 generations, 7 days)
- `ls` / `la` / `lt` - eza (list, all, tree)
- `cat` - bat
- `man` - batman
- `diff` - batdiff
- `grep` - batgrep
- `open` - xdg-open
- `cc` - claude code (skip permissions)
- `qalc` - libqalculate with autocalc mode

## how i do projects

Each repo gets a `flake.nix` with a devshell and an `.envrc` that says `use flake`. cd in, direnv loads everything, cd out and it unloads. All project deps are scoped to that directory

## determinate nix

Running [Determinate Nix](https://github.com/DeterminateSystems/determinate) instead of stock. Flakes are stable (no `experimental-features` needed), lazy trees are on by default

First rebuild needs extra cache flags since your system has no idea where to get their stuff yet:

```
sudo nixos-rebuild boot --flake ~/dotfiles --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
```

Use `boot` not `switch` for that first one, it swaps the dbus implementation under you. Reboot and every rebuild after is normal

## formatting

`nix fmt` runs alejandra, `nix flake check` runs alejandra + statix
