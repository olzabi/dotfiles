#!/usr/bin/env bash
# Re-theme community channels after `tv update-channels` (cable/ is not tracked):
# bat previews keep bat's own darkvoid theme (community channels force BAT_THEME=ansi),
# git previews go through delta (darkvoid), directory previews through eza. Idempotent.
set -euo pipefail
cable=${1:-"$(dirname "$0")/cable"}
sed -i '/^env = { BAT_THEME = "ansi" }$/d' "$cable"/*.toml
for c in git-diff git-log git-branch git-reflog git-stash git-tags; do
  f=$cable/$c.toml; [[ -f $f ]] || continue
  grep -q 'delta --width=variable' "$f" ||
    sed -i -E '/^\[preview\]/,/^\[/{s#^(command = "[^"]*--color=always[^"]*)"$#\1 | delta --width=variable"#}' "$f"
done
for c in dirs zoxide; do
  f=$cable/$c.toml; [[ -f $f ]] || continue
  sed -i "s#^command = \"ls -la --color=always '{}'\"#command = \"eza -la --group-directories-first --icons --color=always '{}'\"#" "$f"
done
