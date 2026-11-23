#!/usr/bin/env bash
# Waybar bell for swaync: status JSON, and click actions (refresh via signal 9).
set -euo pipefail

refresh_waybar() { pkill -RTMIN+9 waybar 2>/dev/null || true; }

case "${1:-status}" in
  panel) swaync-client -t -sw ;;
  toggle) swaync-client -d -sw >/dev/null; refresh_waybar ;;
  dismiss) swaync-client -C -sw; refresh_waybar ;;
  status)
    if ! n=$(swaync-client -c -sw 2>/dev/null); then
      printf '{"text":"","tooltip":"swaync is not running","class":"error"}\n'
      exit 0
    fi
    text=""; [ "$n" -gt 0 ] && text=" $n"
    help='Left click: notification center\\nRight click: Do Not Disturb\\nMiddle click: clear all'
    if [ "$(swaync-client -D -sw)" = true ]; then
      printf '{"text":"%s","tooltip":"Do Not Disturb is on (%s waiting)\\n%s","class":"dnd"}\n' "$text" "$n" "$help"
    else
      printf '{"text":"%s","tooltip":"%s notifications\\n%s","class":"enabled"}\n' "$text" "$n" "$help"
    fi
    ;;
  *) printf 'Usage: %s [status|panel|toggle|dismiss]\n' "$0" >&2; exit 2 ;;
esac
