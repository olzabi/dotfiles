#!/bin/sh
# SessionStart/SessionEnd: label this herdr-core terminal claude.session=<id> (and claude.cwd), so
# config/zsh/conf.d/95-claude-resume.zsh can `claude --resume` it when the core respawns the terminal's
# shell after a reboot. herdr TUI did this itself (pane.report_agent_session); herdr-app does not.
# Usage: herdr-claude-session.sh set|clear
[ -n "${HC_TERMINAL_ID:-}" ] && [ -z "${CLAUDE_JOB_DIR:-}" ] && command -v hc >/dev/null 2>&1 || exit 0
input=$(cat)
field() { printf '%s' "$input" | jq -r ".$1 // empty" 2>/dev/null; }
[ -n "$(field agent_id)" ] && exit 0
# only the claude in the terminal's foreground, not `claude -p` from scripts or agents nested under it
fg=$(hc get --json "$HC_TERMINAL_ID" 2>/dev/null | jq -r '.foreground.pid // empty')
[ -n "$fg" ] || exit 0
p=$PPID
while [ "${p:-1}" -gt 1 ] && [ "$p" != "$fg" ]; do p=$(ps -o ppid= -p "$p" | tr -d ' '); done
[ "$p" = "$fg" ] || exit 0
case $1 in
  set)
    id=$(field session_id)
    [ -n "$id" ] && hc label "$HC_TERMINAL_ID" "claude.session=$id" "claude.cwd=$(field cwd)" ;;
  clear)
    # shortcut: reason "other" covers signal deaths (shutdown, reboot), which must keep the label for the resume
    [ "$(field reason)" = other ] || hc label "$HC_TERMINAL_ID" claude.session= claude.cwd= ;;
esac >/dev/null 2>&1
exit 0
