#!/usr/bin/env bash
# Wi-Fi popup menu (NetworkManager + rofi).
menu="$HOME/.config/waybar/scripts/menu-popup.sh"

radio=$(nmcli radio wifi)
nmcli dev wifi rescan >/dev/null 2>&1 &   # refresh in background; ignored if too frequent

entries=(); acts=()
add() { entries+=("$1"); acts+=("$2"); }

bars() {
  local s=$1
  if   (( s >= 75 )); then echo "▂▄▆█"
  elif (( s >= 50 )); then echo "▂▄▆ "
  elif (( s >= 25 )); then echo "▂▄  "
  else                     echo "▂   "
  fi
}

if [[ $radio == enabled ]]; then
  add "Turn Wi-Fi off" toggle
  add "Rescan"         rescan
else
  add "Turn Wi-Fi on"  toggle
fi
add "Advanced (nmtui)" nmtui

if [[ $radio == enabled ]]; then
  declare -A seen
  # --escape no: SSID is the last field, so colons inside it survive `read`.
  while IFS=: read -r inuse signal sec ssid; do
    [[ -z $ssid || -n ${seen[$ssid]:-} ]] && continue
    seen[$ssid]=1
    mark=" "; kind=net
    if [[ $inuse == "*" ]]; then mark="●"; kind=active; fi
    shown=${sec:-open}; [[ $shown == "--" ]] && shown=open
    add "$(printf '%s %s  %-30s %s' "$mark" "$(bars "${signal:-0}")" "$ssid" "$shown")" "$kind|${sec:---}|$ssid"
  done < <(nmcli --escape no -t -f IN-USE,SIGNAL,SECURITY,SSID dev wifi list --rescan no \
             | sort -t: -k1,1r -k2,2nr)
fi

idx=$(printf '%s\n' "${entries[@]}" | "$menu" -format i -no-custom -p "Wi-Fi") || exit 0
[[ -z $idx || $idx -lt 0 ]] && exit 0
act=${acts[$idx]}

say() { notify-send -a "Wi-Fi" "Wi-Fi" "$1"; }

case $act in
  toggle)
    if [[ $radio == enabled ]]; then nmcli radio wifi off; else nmcli radio wifi on; fi ;;
  rescan)
    nmcli dev wifi rescan >/dev/null 2>&1; sleep 2; exec "$0" ;;
  nmtui)
    exec kitty --class popup-nmtui -e nmtui ;;
  active\|*)
    dev=$(nmcli -t -f DEVICE,TYPE dev | awk -F: '$2=="wifi"{print $1; exit}')
    if [[ -n $dev ]] && nmcli dev disconnect "$dev" >/dev/null 2>&1; then
      say "Disconnected"
    else
      say "Could not disconnect"
    fi ;;
  net\|*)
    rest=${act#*|}; sec=${rest%%|*}; ssid=${rest#*|}
    if nmcli -t -f NAME connection show | grep -Fxq -- "$ssid"; then
      out=$(nmcli connection up id "$ssid" 2>&1); rc=$?
    elif [[ $sec == "--" ]]; then
      out=$(nmcli dev wifi connect "$ssid" 2>&1); rc=$?
    else
      pass=$("$menu" -password -p "Password for $ssid" \
               -theme-str 'listview { enabled: false; }' </dev/null) || exit 0
      [[ -z $pass ]] && exit 0
      out=$(nmcli dev wifi connect "$ssid" password "$pass" 2>&1); rc=$?
    fi
    if (( rc == 0 )); then say "Connected to $ssid"; else say "Failed: ${out##*$'\n'}"; fi ;;
esac
