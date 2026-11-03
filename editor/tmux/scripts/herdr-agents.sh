#!/bin/sh
# Pick a herdr agent from tmux, focus it in herdr and raise herdr's kitty window (niri, app-id "herdr").
agents=$(herdr agent list 2>/dev/null) || { echo "herdr is not running"; sleep 1; exit 1; }
pane=$(printf '%s' "$agents" |
  jq -r '.result.agents[] | [.pane_id, .agent_status, .agent, (.cwd | sub(env.HOME; "~")), .terminal_title_stripped] | @tsv' |
  fzf --delimiter='\t' --with-nth=2.. --preview 'herdr agent read {1} --lines 60' --preview-window=down,60% |
  cut -f1)
[ -n "$pane" ] || exit 0
herdr agent focus "$pane" >/dev/null
win=$(niri msg -j windows | jq -r 'first(.[] | select(.app_id == "herdr") | .id) // empty')
[ -n "$win" ] && niri msg action focus-window --id "$win"
