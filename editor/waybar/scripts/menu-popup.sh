#!/usr/bin/env bash
# Shared rofi popup, anchored top-right just under the bar.
# Extra arguments are passed straight to rofi.
exec rofi -dmenu -i \
  -theme-str 'window { location: northeast; anchor: northeast; x-offset: -16px; y-offset: 52px; width: 460px; }' \
  "$@"

