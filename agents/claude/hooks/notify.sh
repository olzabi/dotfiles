#!/usr/bin/env bash
# Notification hook: desktop alert when Claude is waiting on the user.
# Inside herdr, herdr's own toasts (ui.toast.delivery = "system") already cover this, and only for unfocused panes.
[ "${HERDR_ENV:-}" = 1 ] && exit 0
input=$(cat)
msg=$(jq -r '.message // "Claude needs attention"' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
project=$(basename "$cwd")
# One wait fires several Notification events (idle_prompt, agent_completed, ...) within ~2s: alert once per folder per 10s.
stamp="${XDG_RUNTIME_DIR:-/tmp}/claude-notify-$(printf %s "$cwd" | md5sum | cut -c1-12)"
exec 9>"$stamp.lock"
flock -w 2 9 || exit 0
[ -f "$stamp" ] && [ $(($(date +%s) - $(stat -c %Y "$stamp"))) -lt 10 ] && exit 0
touch "$stamp"
notify-send -a "Claude Code" -u normal "Claude Code${project:+ · $project}" "$msg"
