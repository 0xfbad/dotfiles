_: {
  flake.modules.homeManager.shell-functions = _: {
    # autoloaded, so the bodies are parsed on first call instead of in every pane
    programs.zsh.siteFunctions = {
      ff = ''
        local file
        file=$(fzf --preview 'bat --color=always --style=numbers --line-range=:200 {}')
        [[ -n "$file" ]] && ''${=EDITOR:-hx} "$file"
      '';

      # --files-from implies --relative, the selection keeps its layout under the target directory
      sff = ''
        (( $# < 1 )) && { print -u2 "usage: sff <host>[:<path>]"; return 1 }
        local target="$1"
        [[ "$target" != *:* ]] && target="$target:"
        fzf --multi --preview 'bat --color=always --style=numbers --line-range=:200 {}' |
          rsync -av --files-from=- . "$target"
      '';

      ga = ''
        (( $# < 1 )) && { print -u2 "usage: ga <branch-name>"; return 1 }
        local branch="$1" main wt
        main=$(git worktree list --porcelain | head -1 | cut -d' ' -f2-) || return 1
        wt="''${main}--''${branch}"
        git worktree add -b "$branch" "$wt" 2>/dev/null ||
          git worktree add "$wt" "$branch" || return 1
        cd "$wt"
      '';

      gd = ''
        (( $# < 1 )) && { print -u2 "usage: gd <branch-name>"; return 1 }
        local branch="$1" main
        main=$(git worktree list --porcelain | head -1 | cut -d' ' -f2-) || return 1
        cd "$main" || return 1
        git worktree remove "''${main}--''${branch}" || return 1
        git branch -d "$branch" ||
          print -u2 "not fully merged, tip is $(git rev-parse --short "$branch"); force with: git branch -D $branch"
      '';

      # forwards go on the ControlMaster, so they outlive this command
      fip = ''
        (( $# < 2 )) && { print -u2 "usage: fip <host> <port1> [port2] ..."; return 1 }
        local host="$1" port
        shift
        ssh -O check "$host" 2>/dev/null ||
          ssh -f -N -o ExitOnForwardFailure=yes "$host" || return 1
        for port in "$@"; do
          ssh -O forward -L "$port:localhost:$port" "$host" &&
            print "forwarding localhost:$port -> $host:$port"
        done
      '';

      dip = ''
        (( $# < 2 )) && { print -u2 "usage: dip <host> <port1> [port2] ..."; return 1 }
        local host="$1" port
        shift
        for port in "$@"; do
          ssh -O cancel -L "$port:localhost:$port" "$host" &&
            print "stopped forwarding port $port"
        done
      '';

      lip = ''
        ss -ltnpH 2>/dev/null | grep ssh || print "no active forwards"
      '';

      gl = ''
        local show='grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | xargs -r git show --color=always'
        git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
          fzf --ansi --no-sort --with-shell 'zsh -c' \
            --preview "$show" \
            --bind "enter:execute($show | less -R)"
      '';

      gdf = ''
        local root args
        root=$(git rev-parse --show-toplevel) || return 1
        # requote args so the preview subshell sees them intact
        args="''${(j: :)''${(q)@}}"
        git diff --name-only "$@" |
          fzf --preview "git -C ''${(q)root} diff --color=always $args -- {}" \
            --preview-window=right:70%
      '';

      ns = ''
        nh search "$@"
      '';

      # --scope takes an attached value only, detached it is parsed as the query
      no = ''
        nh search options --scope=home-manager "$@"
      '';

      nf = ''
        (( $# < 1 )) && { print -u2 "usage: nf <binary>"; return 1 }
        nix-locate --whole-name "bin/$1"
      '';

      mkcd = ''
        mkdir -p "$1" && cd "$1"
      '';

      port = ''
        (( $# < 1 )) && { print -u2 "usage: port <port>"; return 1 }
        ss -tulpnH "sport = :$1" | grep . || print "nothing on port $1"
      '';
    };
  };
}
