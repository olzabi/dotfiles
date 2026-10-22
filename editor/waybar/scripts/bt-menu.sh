#!/usr/bin/env bash
MENU="${BT_MENU:-rofi -dmenu}" # or: "wofi --dmenu"
TERM_CMD="${TERMINAL:-kitty}"

refresh() { pkill -RTMIN+8 waybar; }
powered() { bluetoothctl show | grep -q 'Powered: yes'; }
toggle() {
  if powered; then bluetoothctl power off; else bluetoothctl power on; fi
  refresh
}

[[ "$1" == toggle ]] && {
  toggle
  exit 0
}

if ! powered; then
  choice=$(printf '󰂯 Turn on Bluetooth\n' | $MENU) || exit 0
  [[ -n "$choice" ]] && toggle
  exit 0
fi

mapfile -t connected < <(bluetoothctl devices Connected | awk '{print $2}')
declare -A map state
entries=()

while read -r _ mac name; do
  [[ -z "$mac" ]] && continue
  if printf '%s\n' "${connected[@]}" | grep -qx "$mac"; then
    label="󰂱 $name  (connected)"
    state[$label]=1
  else
    label="󰂲 $name"
    state[$label]=0
  fi
  map[$label]="$mac"
  entries+=("$label")
done < <(bluetoothctl devices Paired)

off="󰂲 Turn off Bluetooth"
tui="󰒓 Pair new device…"
choice=$(printf '%s\n' "${entries[@]}" "$tui" "$off" | $MENU) || exit 0

case "$choice" in
"$off") toggle ;;
"$tui") exec $TERM_CMD -e bluetoothctl ;;
"") exit 0 ;;
*)
  mac="${map[$choice]}"
  [[ -z "$mac" ]] && exit 0
  if [[ "${state[$choice]}" == 1 ]]; then
    bluetoothctl disconnect "$mac"
  else bluetoothctl connect "$mac"; fi
  refresh
  ;;
esac
