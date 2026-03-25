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
    terminal.nix               zsh, starship, atuin, wezterm, zellij
    desktop.nix                browsers, media, comms, gaming
    development.nix            LSPs, dev tools, security
    helix.nix                  editor
    pycharm.nix                jetbrains
```

## stealing this

Take whatever you want. Clone to `~/dotfiles` on a bare NixOS system and go through the stuff you need to change

I'm `fbad` in a bunch of places (user def in `modules/features/common.nix`, home-manager in `modules/home/default.nix`, probably others). Grep for it, swap in yours

Copy a host dir to your own name, replace the hardware config with `nixos-generate-config --show-hardware-config` output. Hostname in `configuration.nix` matches the directory. Set your bootloader, kernel modules, whatever. The `default.nix` registers the host as `flake.nixosConfigurations.yourhostname`, just copy desktop's and change the name

Features are all optional, just import the ones you want in your host's `configuration.nix`

`sudo nixos-rebuild switch --flake ~/dotfiles#yourhostname` and pray

## how i do projects

Each repo gets a `flake.nix` with a devshell and an `.envrc` that says `use flake`. cd into the project, direnv loads the environment, cd out and it's gone. `, sometool` (comma, via nix-index-database) for when you need something quick without writing a whole devshell for it

## determinate nix

Running [Determinate Nix](https://github.com/DeterminateSystems/determinate) instead of stock. Flakes are stable (no `experimental-features` needed), lazy trees are on by default

First rebuild needs extra cache flags since your system has no idea where to get their stuff yet:

```
sudo nixos-rebuild boot --flake ~/dotfiles --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
```

Use `boot` not `switch` for that first one, it swaps the dbus implementation under you. Reboot and every rebuild after is normal

## formatting

`nix fmt` runs alejandra, `nix flake check` runs alejandra + statix
