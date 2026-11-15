#!/usr/bin/env bash
set -euo pipefail

refresh_waybar() {
  pkill -RTMIN+9 waybar 2>/dev/null || true
}

case "${1:-status}" in
  toggle)
    makoctl mode -t do-not-disturb
    refresh_waybar
    exit 0
    ;;
  restore)
    makoctl restore || true
    refresh_waybar
    exit 0
    ;;
  dismiss)
    makoctl dismiss --all
    refresh_waybar
    exit 0
    ;;
  status)
    if ! command -v makoctl >/dev/null 2>&1; then
      printf '{"text":"","tooltip":"makoctl is unavailable","class":"error"}\n'
      exit 0
    fi

    if makoctl mode 2>/dev/null | grep -Fxq 'do-not-disturb'; then
      printf '{"text":"","tooltip":"Do Not Disturb is on\\nLeft click: resume notifications\\nMiddle click: restore last notification\\nRight click: dismiss all","class":"dnd"}\n'
    else
      printf '{"text":"","tooltip":"Notifications are enabled\\nLeft click: pause notifications\\nMiddle click: restore last notification\\nRight click: dismiss all","class":"enabled"}\n'
    fi
    ;;
  *)
    printf 'Usage: %s [status|toggle|restore|dismiss]\n' "$0" >&2
    exit 2
    ;;
esac
