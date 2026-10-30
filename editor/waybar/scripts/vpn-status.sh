#!/usr/bin/env bash
# VPN status: NetworkManager profiles (connected/connecting) + raw tun/tap/wireguard
# interfaces (e.g. `sudo openvpn`). Empty text hides the module.
trap 'pkill -P $$' EXIT

status() {
  local up="" connecting="" type state name d ifc ip cfg label tip="" ifaces=()

  # NetworkManager VPN / WireGuard profiles
  while IFS=: read -r type state name; do
    [[ $type == vpn || $type == wireguard ]] || continue
    case $state in
    activated) up+="${up:+, }$name" ;;
    activating) connecting+="${connecting:+, }$name" ;;
    esac
  done < <(nmcli --escape no -t -f TYPE,STATE,NAME connection show --active 2>/dev/null)

  # Any tunnel interface (covers plain `sudo openvpn` too)
  for d in /sys/class/net/*; do
    ifc=${d##*/}
    if [[ -e $d/tun_flags || $ifc == tun* || $ifc == tap* || $ifc == wg* ]] ||
      grep -qs '^DEVTYPE=wireguard' "$d/uevent"; then
      ip=$(ip -4 -o addr show dev "$ifc" 2>/dev/null | awk '{print $4; exit}')
      ifaces+=("$ifc")
      tip+="$ifc${ip:+ ($ip)}\\n"
    fi
  done

  if [[ -z $up && ${#ifaces[@]} -gt 0 ]]; then
    # Not an NM profile: name it after the .ovpn file if openvpn is running
    cfg=$(pgrep -a openvpn 2>/dev/null | grep -oE '[^ =]+\.(ovpn|conf)' | head -n1)
    cfg=$(basename "${cfg:-}")
    cfg=${cfg%.ovpn}
    cfg=${cfg%.conf}
    up=${cfg:-${ifaces[*]}}
  fi

  up=${up//\"/}
  connecting=${connecting//\"/}
  if [[ -n $up ]]; then
    printf '{"text":"󰌾 %s","class":"connected","tooltip":"VPN connected: %s\\n%s"}\n' "$up" "$up" "${tip%\\n}"
  elif [[ -n $connecting ]]; then
    printf '{"text":"󰌾 %s…","class":"connecting","tooltip":"VPN connecting: %s"}\n' "$connecting" "$connecting"
  else
    printf '{"text":"","class":"disconnected","tooltip":"VPN off"}\n'
  fi
}

status
# Re-run on NM events and link changes; the timeout also catches raw openvpn starting/stopping.
while true; do
  while IFS= read -r -t 5 _; do status; done < <(
    nmcli monitor &
    ip monitor link address
    wait
  )
  status
done
