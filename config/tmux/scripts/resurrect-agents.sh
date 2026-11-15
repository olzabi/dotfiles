#!/usr/bin/env bash
# tmux-resurrect post-save-layout hook ($1 = the save file just written): every pane running Claude Code is saved as
# `claude --resume <its current session id>` (other args kept), so a restore reopens that pane's conversation,
# like herdr's resume_agents_on_restore. Ids come from Claude's own $CLAUDE_CONFIG_DIR/sessions/<pid>.json.
set -u
file=${1:?save file}
cfg=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
procs=$(ps -eo pid=,ppid=)

# session<TAB>window<TAB>pane<TAB>claude session id, for panes with a Claude process (the pane's own or a descendant)
map=$(tmux list-panes -a -F '#{session_name}	#{window_index}	#{pane_index}	#{pane_pid}' |
  while IFS=$'\t' read -r s w p root; do
    for pid in $(awk -v r="$root" '{ kid[$2] = kid[$2] " " $1 }
      END { q = r; while (q != "") { n = split(q, a, " "); q = ""; for (i = 1; i <= n; i++) { print a[i]; q = q kid[a[i]] } } }' <<<"$procs"); do
      f=$cfg/sessions/$pid.json
      [ -f "$f" ] || continue
      id=$(jq -r '.sessionId // empty' "$f")
      [ -n "$id" ] && printf '%s\t%s\t%s\t%s\n' "$s" "$w" "$p" "$id"
      break
    done
  done)
[ -n "$map" ] || exit 0

awk -F'\t' -v OFS='\t' '
  NR == FNR { id[$1 FS $2 FS $3] = $4; next }
  $1 == "pane" && (($2 FS $3 FS $6) in id) {
    cmd = substr($11, 2) # saved as ":<full command>"; empty when claude is the pane process itself
    if (cmd == "") cmd = "claude"
    gsub(/ (--resume|-r) [^ ]+/, "", cmd); gsub(/ (--continue|-c)( |$)/, " ", cmd); sub(/ +$/, "", cmd)
    n = index(cmd " ", " ")
    $11 = ":" substr(cmd, 1, n - 1) " --resume " id[$2 FS $3 FS $6] substr(cmd, n)
  }
  { print }' <(printf '%s\n' "$map") "$file" > "$file.tmp" && mv "$file.tmp" "$file"
