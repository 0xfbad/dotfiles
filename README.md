# dotfiles

Personal dotfiles for NixOS and every other hipster riced app I use via home-manager. Following the [dendritic pattern](https://vimjoyer.dev/p/organizing-nix-config/) from vimjoyer's video, everything in `modules/` gets auto-discovered by flake-parts + import-tree so you never have to manually wire imports in the flake

Inspiration and things stolen from some other cool dotfiles:
- https://github.com/JakeGinesin/nix-config
- NSS, not public :( (you know who u are, thx for nixpilling me and answering all my dumb questions)

## layout

```
flake.nix
modules/
  flake-parts.nix
  formatting.nix              treefmt, alejandra, statix
  hosts/
    desktop/                   RTX 3090, dual monitor, GRUB, intel cpu, xpadneo
    laptop/                    Discrete RTX 4090, systemd-boot, LUKS, intel cpu, iwd
  features/
    hyprland.nix               compositor, scrolling layout, keybinds, wallpaper, window rules
    greetd.nix                 tuigreet + uwsm
    common.nix                 nix settings, locale, bluetooth, user, fontconfig
    nvidia.nix                 GPU drivers, wayland session vars
    audio.nix                  pipewire
    virtualization.nix         docker (log rotation), libvirt, qemu
    anonymity.nix              tor, dnscrypt
    networking.nix             networkmanager, dns
    flatpak.nix                flatpak, sober
    determinate.nix            determinate nix
  home/
    default.nix                home-manager wiring
    terminal.nix               packages (cli utils, compression, networking, system tools)
    desktop.nix                packages (browsers, media, comms, gaming, video editing)
    development.nix            packages (LSPs, dev tools, security, ai), direnv
    helix.nix                  editor config, nixd + nil + harper + hyprls
    git.nix                    git settings (rebase, histogram diffs, rerere, verbose commits, difftastic)
    shell-functions.nix        ff (fzf+bat), git worktree helpers, ssh port forwarding
    waybar.nix                 status bar, weather, pomodoro, caffeine toggle, catppuccin OLED
    mako.nix                   notification daemon
    walker.nix                 app launcher, clipboard, calculator, emoji, websearch
    swayosd.nix                volume/brightness OSD
    hyprlock.nix               lock screen
    hypridle.nix               idle management (auto-lock, DPMS)
    firefox.nix                declarative profile, search engines, privacy
    zsh.nix                    shell, aliases, functions, tab completion
    wezterm.nix                terminal emulator
    atuin.nix                  shell history
    bat.nix                    cat replacement + extras
    eza.nix                    ls replacement + theme
    yazi.nix                   file manager + catppuccin
    gitui.nix                  git TUI + theme
    zellij.nix                 multiplexer
    starship.nix               prompt (mauve accent, git status)
    zoxide.nix                 smart cd
    startpage.nix              custom firefox homepage, catppuccin palette
    dolphin.nix                file manager config
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

- SSH ControlMaster multiplexes connections to the same host over one socket, so your second ssh is instant (no handshake, no auth). ControlPersist keeps it alive for 10 minutes after disconnect, compression on by default
- DNS over HTTPS via dnscrypt-proxy (no local or ISP snooping), mDNS and LLMNR disabled so your hostname doesn't leak on local networks
- OLEDmaxxing theme, everything is fully black with catppuccin mocha mauve accent on every app that supports it
- Hyprland with niri-style scrolling layout by default (infinite horizontal columns, cycle column widths with Super+Alt+=/-, scroll viewport with Super+[/]), Super+\\ toggles back to dwindle
- Modular desktop shell inspired by [Omarchy](https://github.com/basecamp/omarchy): waybar, mako notifications, walker launcher (clipboard history, calc, emoji, websearch all built in), swayosd for volume/brightness popups, hyprlock + hypridle for lock and auto-sleep
- wlr-which-key on Super+D for quick actions (screenshots, recording, bluetui, impala wifi, lazydocker, hyprmon monitor config, volume mixer, dolphin)
- Walker launcher on Super+Space with `$` prefix for clipboard history, `=` for calculator, `@` for websearch
- Scratchpad workspace (Super+S), window groups (Super+G), pop-out float+pin (Super+O)
- hyprdim auto-dims inactive windows so you can tell what's focused without borders, wl-clip-persist keeps clipboard alive after closing the source app
- Monitor config lives in a mutable `monitors.conf` that gets sourced by the nix-managed config, so hyprmon TUI can save monitor layouts and they survive rebuilds
- Wezterm + zellij (basically better tmux, sane config, built-in layouts)
- Yazi for file browsing (more modern ranger with image previews)
- Helix with LSPs for like 10 languages, nixd for NixOS/home-manager option completion, harper for grammar checking in markdown and git commits, hyprls for hyprland config diagnostics. Statusline changes color per mode, instant completions, tab bar for multiple buffers, indent guides, inlay hints for type annotations
- Git config with histogram diffs, colorMoved, rerere (remembers conflict resolutions), zdiff3 conflict markers (shows original base alongside both sides), autoSquash + autoStash on rebase, force-push safety net, typo autocorrect. Difftastic as `git difftool` for structural diffs via tree-sitter
- `gl` function: fzf-powered git log with live diff preview per commit. `gdf` for browsing changed files with per-file diffs. `ff` for fzf + bat file finder. `ga`/`gd` for git worktree add/remove. `fip`/`dip`/`lip` for SSH port forwarding
- Atuin for shell history (searchable, syncs across machines if you want)
- Zoxide instead of cd (learns your frequent dirs, `cd foo` jumps to ~/whatever/foo)
- Starship prompt with mauve accent, truncated directory, italic git branch
- Bat instead of cat (syntax highlighting, git diff integration, batman for man pages)
- Eza instead of ls (icons, git status, tree view)
- Dust instead of du (visual disk usage bars, sorted by size)
- sd instead of sed (normal regex syntax, no escaping nonsense)
- procs instead of ps (tree view, per-process ports, docker container awareness)
- doggo instead of dig (colored output, DoH/DoT, JSON mode)
- duf instead of df (grouped table view by device type, adjusts to terminal width)
- viddy instead of watch (diff highlighting between runs, history scrollback)
- choose instead of cut/awk (human-friendly field selection, negative indexing)
- trippy instead of traceroute (real-time latency graphs per hop, multi-protocol)
- Lazydocker for Docker TUI, bluetui and impala for bluetooth and wifi TUIs
- Greetd login with system specs on screen (CPU, RAM, GPU, disk, IP)
- Keybind cheat sheet popup on Super+Shift+? via wezterm
- Wallpaper rotation from ~/dotfiles/wallpapers/ via swww, different image per monitor, grow-from-center transitions, shuffles every 30 minutes
- Dolphin file manager with full catppuccin kdeglobals color scheme and Kvantum theming
- Bibata cursor theme
- Cowsay greeting that changes based on time of day
- Some shell functions for quickly optimizing videos and images (`optimize-video`, `optimize-image`)
- Trufflehog and gitleaks for secret scanning (trufflehog verifies if leaked creds are still live)
- age + sops for secret management (age is simple GPG replacement, sops encrypts values in config files leaving keys readable for diffs)
- My more used cyber tools (nmap, burpsuite, ghidra, gdb+gef, pwntools, binwalk, imhex, etc)
- Waybar with pomodoro timer (walker prompt for task name, countdown in the bar, logs sessions), weather via wttr.in with detailed tooltip, and caffeine toggle to inhibit idle
- hypr-dynamic-cursors plugin (cursor tilts in movement direction, shake-to-find when you lose it on multi-monitor)
- Super+Ctrl+Scroll for screen zoom at cursor position, 10% increments up to 10x
- Animated wallpaper transitions via swww (fade, wipe, grow)
- cliphist for searchable clipboard history (text and images, piped through walker)
- Claude Code and opencode for slopmaxxing
- Comma via nix-index-database (i.e. `, supertuxkart` instead of `nix shell nixpkgs#supertuxkart`)
- nh for nixos rebuilds, shows you a diff of what's changing before it applies
- `rebuild` and `update` aliases run `nix flake check` (alejandra + statix) before applying so you never deploy broken config
- Nix store auto-GC kicks in at 5GB free and cleans up to 20GB, so builds don't fail on a full disk and you don't have to remember to run gc manually
- Channels completely killed, global flake registry disabled, all flake inputs pinned to the lockfile via nix registry so `nix run nixpkgs#`, `nix run home-manager#`, etc. resolve instantly from local store
- systemd-oomd watching root, system, and user slices so it catches memory pressure before the kernel OOM killer randomly murders your browser
- Watchdog timers (15s runtime, 30s reboot, 60s kexec) auto-recover a hung system, gpt-auto-generator suppressed since NixOS manages mounts declaratively
- Caps lock remapped to escape system-wide (TTY, xwayland, Hyprland)
- Network services don't restart during `nixos-rebuild switch` (no more SSH drops mid-rebuild), boot doesn't wait for network on desktop
- nix-ld so you can run random binaries without the "interpreter not found" song and dance
- Jujutsu (jj) alongside git, modern VCS with undo, auto-commit working copy, colocated with git repos
- Ripdrag for dragging files out of the terminal into GUI apps
- Declarative Firefox with extensions force-installed (uBlock, Bitwarden, Dark Reader, Tampermonkey, Unhook, etc), all telemetry/AI/pocket/sponsored slop nuked, OLED black userChrome, custom search engines (`@np` nix packages, `@no` nixos options, `@nw` wiki, `@hm` home-manager)
- Zed as a gui editor for when you don't want a terminal, stripped down with all the networking/AI/collab stuff off
- btop with GPU monitoring
- sshfs for mounting remote dirs over SSH
- Gaming stack: proton-ge, gamescope, gamemode, mangohud overlay. `gamemoderun mangohud %command%` in steam launch options
- ouch instead of tar/zip/gzip (auto-detects format from extension, `ouch decompress` and `ouch compress` just work)
- trashy instead of rm (moves to FreeDesktop trash, files show up in Dolphin's trash can too)
- gping instead of ping (real-time line graph, multiple hosts on same chart)
- miniserve instead of python -m http.server (file upload, auth, TLS, QR code for URL)
- Screenshots via grimblast with --freeze (screen freezes during selection so content doesn't shift), dark overlay, window/area/monitor modes, satty for annotation, wl-screenrec for hardware-accelerated recording
- Super+Shift+C color picker, copies hex to clipboard
- Now-playing in waybar via playerctl, shows artist and title, click to play/pause, scroll to skip
- pyprland scratchpads: dropdown terminal (Super+A slides from top), volume mixer (Super+Shift+V slides from right, auto-hides on focus loss)
- carapace for shell completions across hundreds of commands from a single binary
- Custom Firefox startpage with catppuccin colors, DuckDuckGo search, quick-link categories, and a wallpaper art panel
- Screen recordings get random dictionary-word filenames (like `coffee-telescope.mp4`) so you never have to name them
- Centralized color palette in `colors.nix`, every module references it instead of hardcoding hex values so changing the theme is one file
- jnv for interactive jq (build filters with live preview instead of guessing)
- numbat scientific calculator with unit support (`3 meters + 2 feet` just works, rejects bad dimensions)
- ast-grep for structural search/replace via tree-sitter (refactor code by pattern, not regex)
- tailspin for zero-config log highlighting (pipe anything through `tspin`, auto-detects dates/IPs/UUIDs/severity)
- process-compose as docker-compose for bare processes (YAML config with dependency ordering, TUI)
- pueue for background task queues that survive terminal closes
- scooter for interactive project-wide find-and-replace with helix integration
- mods for piping anything through an LLM (`cat log | mods "what's wrong"`)
- FZF themed with catppuccin mocha, bat previews on file search, eza tree previews on dir jump
- Ctrl+X Ctrl+E opens your current shell command in helix for editing long one-liners
- Double-Esc prepends sudo to the current command (oh-my-zsh sudo plugin)
- Desktop notification when a command takes over 30 seconds (useful when you're in another zellij pane)
- harlequin SQL IDE in terminal (autocomplete, highlighting, Postgres/DuckDB/SQLite)
- navi interactive cheatsheet (fuzzy search commands, prompts for each arg)
- iwd backend for NetworkManager (faster wifi scans, works with impala TUI)

## aliases

- `rebuild` - nix flake check + nh os switch (lint then apply)
- `update` - nix flake check + nh os switch -u (lint, update flake lock, rebuild)
- `gc` - nh clean all (keeps 3 generations, 7 days)
- `ls` / `la` / `lt` - eza (list, all, tree)
- `cat` - bat
- `man` - batman
- `diff` - batdiff
- `grep` - batgrep
- `open` - xdg-open
- `cc` - claude code (skip permissions)
- `qalc` - libqalculate with autocalc mode
- `clip` - copy to clipboard with trailing newline stripped
- `pwdc` - copy current working directory to clipboard
- `termbin` - pipe output to termbin.com for instant pastebin
- `dupe` - open new terminal in same directory
- `watch` - viddy (watch with diff highlighting)
- `lcc` - copy last command to clipboard
- `ff` - fzf file finder with bat preview, opens in editor
- `gl` - fzf git log with live diff preview
- `gdf` - browse changed files with per-file diffs
- `ns` - quick nix package search
- `mkcd` - mkdir + cd in one
- `port` - what's listening on a port
- `ga` / `gd` - git worktree add/remove
- `fip` / `dip` / `lip` - ssh port forward/disconnect/list

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

`nix fmt` runs alejandra, `nix flake check` runs alejandra + statix. The `rebuild` and `update` aliases run `nix flake check` before applying so you never deploy broken config
