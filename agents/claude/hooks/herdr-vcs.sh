#!/bin/sh
# SessionStart/UserPromptSubmit/Stop/CwdChanged: report this pane's branch to herdr (bin/herdr-vcs).
# Prints nothing: stdout of SessionStart/UserPromptSubmit hooks becomes model context.
[ "${HERDR_ENV:-}" = 1 ] || exit 0
input=$(cat)
# subagents (e.g. isolation: "worktree") share the pane; only the main session owns its $branch
[ -n "$(printf '%s' "$input" | jq -r '.agent_id // empty' 2>/dev/null)" ] && exit 0
# CwdChanged: .cwd is still the old dir, the new one is .new_cwd
cwd=$(printf '%s' "$input" | jq -r '.new_cwd // .cwd // empty' 2>/dev/null)
herdr-vcs "${cwd:-$PWD}" >/dev/null 2>&1
exit 0
