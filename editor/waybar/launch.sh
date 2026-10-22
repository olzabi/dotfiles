#!/usr/bin/env bash
# Start Waybar with the config that matches the running compositor.
dir="$HOME/.config/waybar"
rt="${XDG_RUNTIME_DIR:-/run/user/$UID}"

# A shell started before a compositor restart (tmux!) can hold a stale socket path.
if [[ ! -S ${NIRI_SOCKET:-} ]]; then
  sock=$(ls -t "$rt"/niri.*.sock 2>/dev/null | head -n1)
  [[ -n $sock ]] && export NIRI_SOCKET=$sock
fi

if [[ -S ${NIRI_SOCKET:-} ]]; then
  cfg=niri.jsonc
elif [[ -d $rt/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-_} ]] || pgrep -x Hyprland >/dev/null; then
  cfg=hyprland.jsonc
else
  echo "waybar launcher: no supported compositor (niri/Hyprland) found" >&2
  exit 1
fi

pkill -x waybar 2>/dev/null   # replace any running bar
exec waybar -c "$dir/$cfg" -s "$dir/style.css"

