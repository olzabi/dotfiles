#!/usr/bin/env bash
# Claude Code: settings use custom:darkvoid-auto; custom themes have no light/dark pair, so this writes the current
# one there as a real file (Claude watches its themes dir and repaints live; a retargeted link would not fire).
set -eu
d=$DOTFILES/agents/claude/themes
[[ -d $d ]] || exit 0
src=$DOTFILES/themes/current/claude.json
cmp -s "$src" "$d/darkvoid-auto.json" || cp "$src" "$d/darkvoid-auto.json"
