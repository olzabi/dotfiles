#!/usr/bin/env bash
# Monitor picture follows the theme: light = monitor-mode day, dark = monitor-mode night (profiles in bin/monitor-mode).
command -v ddcutil >/dev/null || exit 0
[[ $1 == light ]] && m=day || m=night
# DDC writes take ~1 s each; don't hold up the other apps' theme switch.
setsid "$DOTFILES/bin/monitor-mode" "$m" >/dev/null 2>&1 &
