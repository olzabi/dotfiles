#!/bin/sh
# UserPromptSubmit/Stop/Notification/SessionEnd: 🤖 working / 💬 waiting in `wt list` for the session's branch.
# Worktrunk's documented setup for agents without its plugin: the plugin is off so Claude creates its own
# worktrees (sparsePaths, symlinkDirectories) instead of its WorktreeCreate hook routing them through wt.
# Usage: wt-marker.sh work|wait|clear. Prints nothing (UserPromptSubmit stdout becomes model context).
command -v wt >/dev/null 2>&1 || exit 0
input=$(cat)
# subagents share the session's checkout or have their own worktree; only the main session marks
[ -n "$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)" ] && exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
cd "${cwd:-$PWD}" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1 || exit 0
case $1 in
  work) wt config state marker set "🤖" ;;
  wait) wt config state marker set "💬" ;;
  clear) wt config state marker clear ;;
esac >/dev/null 2>&1
exit 0
