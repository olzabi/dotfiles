#!/bin/sh
# popup.sh <target-session> <current-session> <path>
prepare() {
  session=$1 root=$2
  win=$(tmux list-windows -t "=$session" -F '#{window_id} #{@root}' 2>/dev/null |
    while read -r id r; do
      [ "$r" = "$root" ] && { echo "$id"; break; }
    done)

  if [ -z "$win" ]; then
    name=$(basename "$root")
    if tmux has-session -t "=$session" 2>/dev/null; then
      win=$(tmux new-window -d -P -F '#{window_id}' -t "=$session:" -c "$root" -n "$name")
    else
      win=$(tmux new-session -d -P -F '#{window_id}' -s "$session" -c "$root" -n "$name")
    fi
    tmux set-option -w -t "$win" @root "$root"
  fi
  tmux select-window -t "$win"
}

find_pane() {
  tmux list-panes -s -t "=$1" -F '#{pane_id}|#{pane_current_path}' |
  while IFS='|' read -r id p; do
    [ -z "$p" ] && continue
    case "$p" in
      "$2")   echo "0 $id" ;;   # pane is exactly at the root
      "$2"/*) echo "1 $id" ;;   # pane is inside the root
    esac
    case "$2" in
      "$p"/*) echo "2 $id" ;;   # root is inside the pane's dir
    esac
  done | sort | head -n1 | cut -d' ' -f2
}

if [ "$1" = "--run" ]; then
  name=$2
  root=$PWD                             # display-popup -d already set this to the origin root
  while [ -n "$name" ]; do
    tmux set -g @popup_next ""
    if tmux has-session -t "=$name" 2>/dev/null; then
      tmux set-option -t "=$name" @root "$root"
      match=$(find_pane "$name" "$root")
      if [ -n "$match" ]; then
        tmux select-window -t "$match"
        tmux select-pane -t "$match"
      else
        pane="=$name:"
        cmd=$(tmux display-message -p -t "$pane" '#{pane_current_command}')
        cur=$(tmux display-message -p -t "$pane" '#{pane_current_path}')
        case "$cmd" in
          sh|bash|zsh|fish|dash)
            [ "$cur" != "$root" ] &&
              tmux send-keys -t "$pane" " cd -- '$root'" Enter ;;
        esac
      fi
    fi
    tmux new-session -A -s "$name" -c "$root"
    name=$(tmux show -gqv @popup_next)
  done
  exit 0
fi

target=$1 current=$2 path=$3

case "$current" in
  popup|subagents)                      # already inside a popup session
    if [ "$current" = "$target" ]; then
      tmux set -g @popup_next ""        # same key: close
    else
      tmux set -g @popup_next "$target" # other key: switch in place
    fi
    tmux detach-client
    ;;
  *)                                    # normal session: open the popup
    root=$(git -C "$path" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$path")
    tmux set -g @popup_root "$root"     # remembered so in-place switches use the origin root
    tmux display-popup -E -w 90% -h 90% -d "$root" "'$0' --run '$target'"
    ;;
esac
