#!/usr/bin/env bash
# niri: config/niri/theme.kdl is a link into themes/current; a retargeted link isn't a file change niri notices.
command -v niri >/dev/null && [[ -n ${NIRI_SOCKET:-} || -n ${WAYLAND_DISPLAY:-} ]] || exit 0
niri msg action load-config-file >/dev/null 2>&1
exit 0
