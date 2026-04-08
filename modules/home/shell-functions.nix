_: {
  flake.homeModules.shell-functions = _: {
    programs.zsh.initContent = ''
      # fzf file finder with bat preview
      ff() {
        local file
        file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers {}')
        [ -n "$file" ] && ''${EDITOR:-hx} "$file"
      }

      # fuzzy find files and send over scp
      sff() {
        (( $# < 1 )) && echo "usage: sff <host>[:<path>]" && return 1
        local target="$1"
        [[ "$target" != *:* ]] && target="$target:"
        fd --type f --hidden --exclude .git |
          fzf --multi --preview 'bat --color=always --style=numbers {}' |
          while IFS= read -r f; do scp "$f" "$target" && echo "sent $f"; done
      }

      # git worktree add
      ga() {
        if [ -z "$1" ]; then
          echo "usage: ga <branch-name>"
          return 1
        fi
        local branch="$1"
        local base
        base=$(basename "$PWD")
        local path="../''${base}--''${branch}"
        git worktree add -b "$branch" "$path"
        cd "$path"
      }

      # git worktree remove
      gd() {
        if [ -z "$1" ]; then
          echo "usage: gd <branch-name>"
          return 1
        fi
        local branch="$1"
        local base
        base=$(basename "$PWD")
        local cwd="$PWD"
        local worktree="../''${base}--''${branch}"
        cd "$(dirname "$cwd")/''${base}" 2>/dev/null || cd ..
        git worktree remove "$worktree" && git branch -D "$branch"
      }

      # ssh forward ports: fip <host> <port1> [port2] ...
      fip() {
        (( $# < 2 )) && echo "usage: fip <host> <port1> [port2] ..." && return 1
        local host="$1"
        shift
        for port in "$@"; do
          ssh -f -N -L "$port:localhost:$port" "$host" && echo "forwarding localhost:$port -> $host:$port"
        done
      }

      # stop forwarded ports: dip <port1> [port2] ...
      dip() {
        (( $# == 0 )) && echo "usage: dip <port1> [port2] ..." && return 1
        for port in "$@"; do
          pkill -f "ssh.*-L $port:localhost:$port" && echo "stopped forwarding port $port" || echo "no forwarding on port $port"
        done
      }

      # list active ssh forwards
      lip() {
        pgrep -af "ssh.*-L [0-9]+:localhost:[0-9]+" || echo "no active forwards"
      }

      # git log with fzf and live diff preview
      gl() {
        git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
          fzf --ansi --no-sort --reverse \
            --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | head -1 | xargs git show --color=always' \
            --bind "enter:execute(grep -o '[a-f0-9]\{7,\}' <<< {} | head -1 | xargs git show --color=always | less -R)"
      }

      # browse changed files with per-file diff preview
      gdf() {
        git diff --name-only "$@" |
          fzf --preview "git diff --color=always $* -- {}" --preview-window=right:70%
      }

      # quick nix package search
      ns() { nix search nixpkgs "$@" --no-update-lock-file 2>/dev/null | head -40; }

      # mkdir and cd into it
      mkcd() { mkdir -p "$1" && cd "$1"; }

      # what's listening on a port
      port() { lsof -i :"$1" 2>/dev/null || echo "nothing on port $1"; }
    '';
  };
}
