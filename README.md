# dotfiles

NixOS + home-manager dotfiles. [Dendritic pattern](https://vimjoyer.dev/p/organizing-nix-config/) via flake-parts + import-tree, everything in `modules/` auto-discovered

Stolen from:
- https://github.com/JakeGinesin/nix-config
- NSS, not public :( (thx for nixpilling me)

## layout

```
flake.nix
modules/
  flake-parts.nix
  formatting.nix              treefmt, alejandra, statix
  hosts/
    desktop/                   RTX 3090, dual monitor, GRUB, intel cpu, xpadneo
    laptop/                    Discrete RTX 4090, systemd-boot, LUKS, intel cpu
  features/
    hyprland.nix               compositor, scrolling layout, keybinds, wallpaper, window rules
    greetd.nix                 tuigreet + uwsm
    common.nix                 nix settings, locale, bluetooth, user, fontconfig
    nvidia.nix                 GPU drivers, wayland session vars
    audio.nix                  pipewire, audio tools (sox, pwvucontrol)
    virtualization.nix         docker, libvirt, qemu
    anonymity.nix              tor, dnscrypt
    networking.nix             networkmanager, dns
    flatpak.nix                flatpak, sober
    determinate.nix            determinate nix
  home/
    default.nix                home-manager wiring
    terminal.nix               CLI packages
    desktop.nix                GUI packages
    development.nix            LSPs, dev tools, security, AI, direnv
    quickshell.nix             desktop shell (bar, launcher, notifications, OSD, session menu, wallpaper picker)
    quickshell/                QML components for quickshell
    helix.nix                  editor, nixd + nil + harper + hyprls
    vcs.nix                    git (histogram diffs, rerere, difftastic), gitui, jujutsu, gh
    ssh.nix                    SSH agent, multiplexing, compression
    shell-functions.nix        ff, git worktree helpers, ssh port forwarding
    hyprlock.nix               lock screen
    hypridle.nix               idle management
    firefox.nix                declarative profile, search engines, privacy, policies, extensions
    zsh.nix                    shell, aliases, tab completion
    wezterm.nix                terminal emulator
    atuin.nix                  shell history
    bat.nix                    cat replacement
    eza.nix                    ls replacement
    yazi.nix                   file manager
    zellij.nix                 multiplexer
    starship.nix               prompt
    zoxide.nix                 smart cd
    colors.nix                 centralized catppuccin palette
    gtk.nix                    GTK/Qt theming
    tealdeer.nix               tldr pages
    dolphin.nix                file manager config
    btop.nix                   system monitor
    mangohud.nix               gaming overlay
    zed.nix                    gui editor
    pycharm.nix                jetbrains
```

## stealing this

Clone to `~/dotfiles` on a bare NixOS system. Grep for `fbad`, swap in your username

Copy a host dir, replace hardware config with `nixos-generate-config --show-hardware-config` output. Features are all optional, import what you want in your host's `configuration.nix`

`nh os switch` and pray

## cool stuff

**desktop shell**
- Quickshell (QML) bar: workspaces, clock, media with cava visualizer, system stats + network graph popout, battery timeline + power profile control, weather + hourly forecast, pomodoro + todo, notifications, caffeine toggle, recording indicator with region overlay
- Launcher on Super+Space (fuzzy search, calculator), keybind cheatsheet on Super+D, session menu, wallpaper picker, OSD

**hyprland**
- Niri-style scrolling layout (infinite horizontal columns, Super+[/] to scroll, Super+Alt+=/- for widths), Super+\\ toggles dwindle
- Scratchpad workspace (Super+S), window groups (Super+G), float+pin (Super+O)
- pyprland scratchpads: dropdown terminal, volume mixer
- hyprdim dims inactive windows, hypr-dynamic-cursors (tilt + shake-to-find), Super+Ctrl+Scroll zoom
- Wallpaper rotation via awww, per-monitor, animated transitions, shuffles every 30 min
- Screenshots via grim + slurp + satty annotation, wf-recorder for recording with dashed region overlay
- Random dictionary-word filenames for recordings (`coffee-telescope.mp4`)
- Monitor config in mutable `monitors.conf` so hyprmon layouts survive rebuilds
- Super+Shift+C color picker

**terminal**
- Wezterm + zellij, helix with LSPs for ~10 languages (nixd, harper, hyprls)
- Atuin history, zoxide cd, starship prompt, carapace completions
- `ff` fzf+bat file finder, `gl`/`gdf` fzf git log/diff browsers, `ga`/`gd` worktree helpers
- Ctrl+X Ctrl+E to edit commands in helix, Double-Esc for sudo, 30s command notification

**git**
- Histogram diffs, colorMoved, rerere, zdiff3 conflicts, autoSquash + autoStash, force-push safety, difftastic

**cli replacements**
- bat/cat, eza/ls, dua/du, sd/sed, procs/ps, q/dig, duf/df, viddy/watch, choose/cut, trippy/traceroute, gping/ping, ouch/tar+zip+gz+bz2+rar+7z, rip2/rm, miniserve/http.server

**nix**
- [Determinate Nix](https://github.com/DeterminateSystems/determinate), channels killed, flake registry pinned to lockfile
- `rebuild`/`update` aliases lint (alejandra + statix) before applying, nh for diffs
- Auto-GC at 5GB free, comma via nix-index-database, nix-ld for random binaries

**system**
- DNS over HTTPS via dnscrypt-proxy, mDNS/LLMNR disabled
- OLED black catppuccin mocha everywhere, centralized palette in `colors.nix`
- systemd-oomd, watchdog timers, caps rebound to escape (mainly for helix, works in tty), network services don't restart during rebuild
- Greetd login with 4-line system specs (OS, CPU, GPU, disk/IP), Bibata cursor
- SSH agent with multiplexing, connection keep-alive, compression

**firefox**
- Declarative profile, extensions force-installed (uBlock, Bitwarden, Dark Reader, etc), telemetry nuked, OLED userChrome
- Custom search engines (`@np` nix packages, `@no` options, `@nw` wiki, `@hm` home-manager)

**other**
- cliphist + quickshell for clipboard history
- Lazydocker, bluetui, wlctl TUIs
- Gaming: proton-ge, gamescope, gamemode, mangohud
- Security: trufflehog, gitleaks, nmap, burpsuite, ghidra, gdb+gef, pwntools, binwalk, imhex
- age + sops for secrets, jujutsu alongside git
- Claude Code and opencode for slopmaxxing
- jnv (interactive jq), numbat (calculator with units), ast-grep, tailspin, mods

## aliases

- `rebuild` / `update` - lint + apply (update also bumps flake lock)
- `gc` - nh clean all (3 generations, 7 days)
- `ls` / `la` / `lt` - eza
- `cat` / `man` / `diff` / `grep` - bat variants
- `cc` - claude code
- `clip` / `pwdc` / `lcc` - clipboard helpers
- `ff` / `gl` / `gdf` - fzf file/git browsers
- `ga` / `gd` - git worktree add/remove
- `fip` / `dip` / `lip` - ssh port forwarding
- `ns` - nix package search
- `dupe` - new terminal in same dir
- `port` - what's on a port
- `mkcd` - mkdir + cd

## determinate nix

First rebuild needs cache flags:

```
sudo nixos-rebuild boot --flake ~/dotfiles --option extra-substituters https://install.determinate.systems --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
```

Use `boot` not `switch` for the first one, it swaps dbus. Reboot and every rebuild after is normal
