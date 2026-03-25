# dotfiles

NixOS config using the [dendritic pattern](https://vimjoyer.dev/p/organizing-nix-config/) with flake-parts + import-tree. Every file in `modules/` gets auto-discovered, no manual imports in the flake.

## structure

```
flake.nix                    one-liner outputs via import-tree
modules/
  flake-parts.nix            systems, custom options
  formatting.nix             treefmt + alejandra + statix
  hosts/
    desktop/                 RTX 3090 desktop (GRUB, dual monitor)
    laptop/                  laptop (systemd-boot, LUKS)
  features/
    hyprland.nix             compositor + all keybinds
    noctalia.nix             bar, notifications, launcher, clipboard
    greetd.nix               login manager (tuigreet + uwsm)
    common.nix               nix settings, locale, bluetooth, user
    nvidia.nix               gpu drivers
    audio.nix                pipewire
    virtualization.nix       docker, libvirt, qemu
    anonymity.nix            tor, dnscrypt
    networking.nix           networkmanager, dns
    flatpak.nix              flatpak + sober
    determinate.nix          determinate nix (stable flakes, lazy trees)
  home/
    default.nix              home-manager integration
    terminal.nix             zsh, starship, atuin, wezterm, zellij, etc
    desktop.nix              gui apps (browsers, media, comms, gaming)
    development.nix          dev tools, LSPs, security tools
    helix.nix                editor config
    pycharm.nix              jetbrains config
```

## adding a new machine

start from a fresh NixOS install, then:

1. copy `modules/hosts/desktop/` to `modules/hosts/yourmachine/`
2. replace the hardware config with the output of `nixos-generate-config --show-hardware-config`
3. update `default.nix` to define `flake.nixosConfigurations.yourmachine`
4. update `configuration.nix` with your hostname, bootloader, and which feature modules to import
5. rebuild: `sudo nixos-rebuild switch --flake ~/dotfiles#yourmachine`

the feature modules are composable. don't need virtualization? don't import it. different gpu? swap nvidia for something else or drop it entirely.

## determinate nix

this config uses [determinate nix](https://github.com/DeterminateSystems/determinate) instead of stock nix. flakes and nix-command are stable (no experimental-features needed), lazy trees are on by default, and you get flakehub cache.

first rebuild after adding determinate needs extra cache flags since the substituter isn't configured yet:

```
sudo nixos-rebuild switch --flake ~/dotfiles \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
```

subsequent rebuilds work normally. also, switching from stock nix to determinate changes the dbus implementation, so use `nixos-rebuild boot` and reboot instead of `switch` for that first one.

## formatting

```
nix fmt        # format everything with alejandra
nix flake check  # verify formatting + statix linting
```

## keybinds

hold `Super + Shift + ?` to see all keybinds in a popup
