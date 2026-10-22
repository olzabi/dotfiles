#!/usr/bin/env bash
# Notification popup menu (mako + rofi).
# Quick actions reuse notifications.sh; picking a history entry copies it.
menu="$HOME/.config/waybar/scripts/menu-popup.sh"
notif="$HOME/.config/waybar/scripts/notifications.sh"

hist=$(makoctl history -j 2>/dev/null)
[[ -z $hist ]] && hist='[]'

entries=("Toggle Do Not Disturb" "Dismiss all" "Restore last dismissed")
fixed=${#entries[@]}

while IFS= read -r line; do entries+=("$line"); done < <(
  jq -r '.[] | [.app_name, .summary, ((.body // "") | gsub("\\s+"; " "))]
              | map(select(. != null and . != "")) | join(" — ") | .[0:110]' <<<"$hist"
)
(( ${#entries[@]} == fixed )) && entries+=("(no dismissed notifications)")

idx=$(printf '%s\n' "${entries[@]}" | "$menu" -format i -no-custom -p "Notifications") || exit 0
[[ -z $idx || $idx -lt 0 ]] && exit 0

case $idx in
  0) "$notif" toggle ;;
  1) "$notif" dismiss ;;
  2) "$notif" restore ;;
  *)
    text=$(jq -r --argjson n "$((idx - fixed))" \
      '.[$n] // empty | [.summary, .body] | map(select(. != null and . != "")) | join("\n")' <<<"$hist")
    [[ -n $text ]] && printf '%s' "$text" | wl-copy && notify-send -a Notifications "Copied to clipboard" ;;
esac

pkill -RTMIN+9 waybar 2>/dev/null   # refresh the bell (signal 9)
exit 0

