#!/usr/bin/env bash
# VPN connect/disconnect menu (NetworkManager + rofi).
menu="$HOME/.config/waybar/scripts/menu-popup.sh"
say() { notify-send -a "VPN" "VPN" "$1"; }

entries=()
acts=()
add() {
  entries+=("$1")
  acts+=("$2")
}

declare -A active
while IFS= read -r u; do active[$u]=1; done \
  < <(nmcli -t -f UUID connection show --active)

count=0
while IFS=: read -r type uuid name; do
  [[ $type == vpn || $type == wireguard ]] || continue
  count=$((count + 1))
  if [[ -n ${active[$uuid]:-} ]]; then
    add "● $name  (disconnect)" "down|$uuid|$name"
  else
    add "○ $name  (connect)" "up|$uuid|$name"
  fi
done < <(nmcli --escape no -t -f TYPE,UUID,NAME connection show)

((count == 0)) && say "No VPN profiles in NetworkManager. Add one in the editor."
add "Edit VPN profiles…" editor

idx=$(printf '%s\n' "${entries[@]}" | "$menu" -format i -no-custom -p "VPN") || exit 0
[[ -z $idx || $idx -lt 0 ]] && exit 0
act=${acts[$idx]}

case $act in
editor) exec nm-connection-editor ;;
up\|*)
  rest=${act#*|}
  uuid=${rest%%|*}
  name=${rest#*|}
  say "Connecting: $name…"
  if out=$(nmcli --ask connection up uuid "$uuid" 2>&1); then
    say "Connected: $name"
  else
    say "Failed: ${out##*$'\n'}"
  fi
  ;;
down\|*)
  rest=${act#*|}
  uuid=${rest%%|*}
  name=${rest#*|}
  nmcli connection down uuid "$uuid" >/dev/null 2>&1 &&
    say "Disconnected: $name" || say "Could not disconnect"
  ;;
esac
