_: {
  flake.homeModules.shell-functions = _: {
    programs.zsh.initContent = ''
      # fzf file finder with bat preview
      ff() {
        local file
        file=$(fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers {}')
        [ -n "$file" ] && ''${EDITOR:-hx} "$file"
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
    '';
  };
}
