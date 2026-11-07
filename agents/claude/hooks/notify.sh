#!/usr/bin/env bash
# Notification hook: desktop alert when Claude is waiting on the user.
# Inside herdr, herdr's own toasts (ui.toast.delivery = "system") already cover this, and only for unfocused panes.
[ "${HERDR_ENV:-}" = 1 ] && exit 0
input=$(cat)
msg=$(jq -r '.message // "Claude needs attention"' <<<"$input")
project=$(basename "$(jq -r '.cwd // empty' <<<"$input")")
notify-send -a "Claude Code" -u normal "Claude Code${project:+ · $project}" "$msg"
