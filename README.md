# dotfiles

NixOS + home-manager on the [dendritic](https://vimjoyer.dev/p/organizing-nix-config/) pattern, flake-parts + import-tree, every file in `modules/` is a module and gets picked up without an import list

Some inspirations:

- [JakeGinesin](https://github.com/JakeGinesin/nix-config)
- NSS (not public, thx for always showing me cool things)
- [Omarchy](https://github.com/basecamp/omarchy), not specifically nix related but I've found some cool tools through the slop tweets I see of it

## modern replacements

- [niri](https://github.com/YaLTeR/niri) over hyprland, scrollable tiling, each workspace is a horizontal strip of columns
- [helix](https://helix-editor.com) over neovim, selection first editing with lsp, tree-sitter and multicursor built in, no plugins needed
- [zellij](https://zellij.dev) over tmux, floating panes, sessions are serialized and can be resurrected after a reboot
- [jujutsu](https://github.com/jj-vcs/jj) on top of git, the working copy is always a commit and `jj undo` reverts any operation, with [mergiraf](https://mergiraf.org) for syntax aware merges and [difftastic](https://difftastic.wilfred.me.uk) for syntax aware diffs
- [atuin](https://atuin.sh) over zsh history, fuzzy search over every command with its exit code, duration and directory
- [zoxide](https://github.com/ajeetdsouza/zoxide) over cd, `z name` jumps to the most used directory matching it
- [starship](https://starship.rs) prompt, shows the jj change id next to the path
- [carapace](https://carapace.sh) over per tool completion scripts, one binary completes hundreds of clis
- [vicinae](https://github.com/vicinaehq/vicinae) over rofi, raycast style launcher with clipboard history and extensions for nix packages, firefox bookmarks and history, and keepassxc
- [nh](https://github.com/nix-community/nh) over nixos-rebuild, shows the package diff before switching and cleans old generations on a timer
- [yazi](https://github.com/sxyazi/yazi) over ranger, previews and directory loads run async
- [comma](https://github.com/nix-community/comma), `, cowsay` runs any nixpkgs program once without installing it
- [tealdeer](https://github.com/tealdeer-rs/tealdeer) for tldr examples, `batman` when the full man page is needed
- [jnv](https://github.com/ynqa/jnv) over jq trial and error, shows the filter result as you type
- [numbat](https://numbat.dev) over bc, math with units that rejects mismatched dimensions
- [ast-grep](https://ast-grep.github.io) over grep for code, patterns are written as code and match the syntax tree
- [tailspin](https://github.com/bensadeh/tailspin) highlights dates, ips, uuids and log levels in anything piped through `tspin`
- [viddy](https://github.com/sachaos/viddy) over watch, keeps every run so you can step back and diff them
- [rip2](https://github.com/MilesCranmer/rip2) over rm, deleted files go to a graveyard and `rip -u` restores the last one
- [q](https://github.com/natesales/q) over dig, also queries doh, dot and doq resolvers
- [ouch](https://github.com/ouch-org/ouch) over tar and unzip, one command for every archive format, picked from the extension
- [scooter](https://github.com/thomasschafer/scooter) over sed for project wide find and replace, each match can be toggled before it is written
- [watchexec](https://watchexec.github.io) over entr, [xh](https://github.com/ducaale/xh) over httpie, [trippy](https://trippy.cli.rs) over traceroute, [gping](https://github.com/orf/gping) over ping, [rdap](https://www.openrdap.org) over whois, [miniserve](https://github.com/svenstaro/miniserve) over `python -m http.server`
- bat for cat, eza for ls, fd for find, ripgrep for grep, sd for sed, procs for ps, duf for df, dua for du, choose for cut
- tuis: gh-dash for github, jjui for jj, lazydocker, lazyjournal for journald, bluetui for bluetooth, wlctl for networkmanager, csvlens for csv, harlequin for sql

Other bits:

- lanzaboote secure boot, luks unlocked by tpm2 plus a pin, hibernate to encrypted swap
- keepassxc for passwords, browser autofill and ssh keys, gnome-keyring for app secrets, unlocked by the login password
- secretspec + age for api keys, encrypted blob for slop skills
- dnscrypt-proxy with dnssec over anonymized relays, so no single server sees both your ip and your queries, plus tor
- oled black catppuccin theme, palette in `colors.nix`
- declarative firefox and thunderbird profiles
- scx_lavd scheduler, zram + systemd-oomd
- treefmt, statix and deadnix in a flake partition, dev inputs stay out of the main lockfile
- screenshots via wayfreeze + slurp, gpu-screen-recorder for quick recordings
- steam with gamescope, gamemode and mangohud
- winboat for windows apps

## stealing this

Clone to `~/dotfiles`, grep for `fbad` and swap in your username. Copy a host dir, regenerate the hardware config, trim the shared `workstation` feature list in `modules/hosts/default.nix`, then run `nh os switch`
