# reap zellij sessions whose panes are all idle shells

current="${ZELLIJ_SESSION_NAME:-}"

is_shell() {
  case "$1" in
    zsh | bash | sh | fish | dash | -zsh | -bash | -sh | -fish) return 0 ;;
    *) return 1 ;;
  esac
}

has_real_proc() {
  local server="$1" child comm
  while IFS= read -r child; do
    [ -n "$child" ] || continue
    comm="$(ps -o comm= -p "$child" 2>/dev/null || true)"
    is_shell "$comm" || return 0
    # a shell with a child is running a real program
    [ -z "$(pgrep -P "$child" 2>/dev/null || true)" ] || return 0
  done < <(pgrep -P "$server" 2>/dev/null || true)
  return 1
}

while read -r pid rest; do
  case "$rest" in
    *zellij*--server*) ;;
    *) continue ;;
  esac
  sock="${rest##*--server }"
  sock="${sock%% *}"
  [ -S "$sock" ] || continue
  name="${sock##*/}"

  [ "$name" = "$current" ] && continue
  # attached if a client holds an established conn to the socket
  ss -x state established 2>/dev/null | grep -qF "$sock" && continue
  has_real_proc "$pid" && continue

  zellij delete-session "$name" --force >/dev/null 2>&1 || true
# -ww keeps ps from truncating the long server arg
done < <(ps -ww -eo pid=,args=)

zellij delete-all-sessions --yes >/dev/null 2>&1 || true
