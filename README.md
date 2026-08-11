# dotfiles

NixOS + home-manager, [dendritic](https://vimjoyer.dev/p/organizing-nix-config/) flake-parts + import-tree, everything in `modules/` is auto-discovered

Some inspirations:

- [JakeGinesin](https://github.com/JakeGinesin/nix-config)
- NSS (not public, thx for always showing me cool things)
- [Omarchy](https://github.com/basecamp/omarchy), not specifically nix related but I've found some cool tools through the slop tweets I see of it

## modern replacements

- [niri](https://github.com/YaLTeR/niri) over a workspace tiler, columns on a scrollable strip, opening a window never resizes the others
- [helix](https://helix-editor.com) over neovim, selection first editing, native multicursor and tree-sitter
- [zellij](https://zellij.dev) over tmux, sessions attach from the browser for pairing, floating panes
- [jujutsu](https://github.com/jj-vcs/jj) alongside git, the working copy is a commit and every operation is undoable, mergiraf syntax aware merges, difftastic diffs
- [atuin](https://atuin.sh) owns the up arrow, every command logged to sqlite with exit code and duration, searchable across all sessions
- [zoxide](https://github.com/ajeetdsouza/zoxide) over cd, learns every directory you visit, `z par` jumps to the best frecency match from anywhere
- [starship](https://starship.rs) prompt with the jj change id inline
- [carapace](https://carapace.sh) completions for hundreds of clis from one binary, same behavior in every shell
- [vicinae](https://github.com/vicinaehq/vicinae) over rofi, raycast style launcher with nix search and clipboard history
- [determinate nix](https://github.com/DeterminateSystems/determinate) with nh, channels killed, registry pinned to the lockfile
- [yazi](https://github.com/sxyazi/yazi) over ranger, async previews
- [comma](https://github.com/nix-community/comma), `, cowsay` runs uninstalled tools from the binary cache
- [tealdeer](https://github.com/tealdeer-rs/tealdeer) over man, `batman` for the full page
- [jnv](https://github.com/ynqa/jnv) for interactive jq, [numbat](https://numbat.dev) for unit aware math
- [ast-grep](https://ast-grep.github.io) over grep for code, search and rewrite the syntax tree with patterns that look like the code itself, [tailspin](https://github.com/bensadeh/tailspin) highlights logs
- [viddy](https://github.com/sachaos/viddy) over watch, records every run so you can rewind and diff them
- [rip2](https://github.com/MilesCranmer/rip2) over rm, deletions land in a graveyard and `rip -u` brings them back
- [q](https://github.com/natesales/q) over dig, supports doh, dot and doq
- [ouch](https://github.com/ouch-org/ouch) over tar flags, infers the format from the extension in both directions
- gh-dash, jjui, lazydocker, bluetui tuis
- bat/cat, eza/ls, sd/sed, procs/ps, duf/df, dua/du, choose/cut, gping/ping, trippy/traceroute, miniserve/http.server

Other bits:

- lanzaboote secure boot, tpm2 luks unlock, hibernate to encrypted swap
- keepassxc as the secrets provider, fdosecrets, ssh agent, with browser integrations
- dnscrypt-proxy doh and tor/i2p
- oled black catppuccin theme, palette in `colors.nix`
- declarative firefox and thunderbird profiles
- scx_lavd scheduler, zram + systemd-oomd
- dev tooling in a flake partition (consumers never evaluate treefmt, statix or git hooks)
- screenshots via wayfreeze + slurp, wl-screenrec for quick recordings
- winboat for windows apps

## stealing this

Clone to `~/dotfiles`, grep for `fbad`, swap in your username. Copy a host dir, regenerate the hardware config, import the features you want. `nh os switch` and pray

First rebuild needs the determinate cache, and `boot` not `switch` since it swaps dbus:

```
sudo nixos-rebuild boot --flake ~/dotfiles \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys "cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM="
```
