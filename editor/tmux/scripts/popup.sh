#!/bin/sh
# popup.sh <target-session> <current-session> <path>
if [ "$1" = "--run" ]; then
  name=$2
  while [ -n "$name" ]; do
    tmux set -g @popup_next ""
    tmux new-session -A -s "$name"
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
    tmux display-popup -E -w 90% -h 90% -d "$path" "'$0' --run '$target'"
    ;;
esac
