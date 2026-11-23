#!/usr/bin/env bash
# bat (and yazi previews, fzf-tab, tv) use --theme=darkvoid-current, a link into themes/current; bat only reads
# themes from its cache, so rebuild the cache when the mode changed.
command -v bat >/dev/null || exit 0
s=${XDG_STATE_HOME:-$HOME/.local/state}/darkvoid; mkdir -p "$s"
[[ $(cat "$s/bat" 2>/dev/null) == "$1" ]] && exit 0
BAT_CONFIG_DIR=$DOTFILES/config/bat bat cache --build >/dev/null 2>&1 && echo "$1" >"$s/bat"
