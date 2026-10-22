#!/usr/bin/env bash
NAME="${KB_NAME:?KB_NAME is not set}"
LABELS=("L" "R") # swap if the halves come out reversed
INTERVAL=60
LOW=20

paths=()
last=""

discover() {
  mapfile -t paths < <(
    busctl --json=short call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
      jq -r --arg n "$NAME" '
      .data[0] as $o
      | [ $o | to_entries[]
          | select(.value["org.bluez.Device1"] != null)
          | select(.value["org.bluez.Device1"].Connected.data == true)
          | select((.value["org.bluez.Device1"].Alias.data // .value["org.bluez.Device1"].Name.data // "")
                   | test($n; "i"))
          | .key ] as $devs
      | $o | to_entries[]
      | select(.key as $k | any($devs[]; . as $d | $k | startswith($d + "/")))
      | select((.value["org.bluez.GattCharacteristic1"].UUID.data? // "") | startswith("00002a19"))
      | .key' | sort
  )
}

while true; do
  [[ ${#paths[@]} -eq 0 ]] && discover

  parts=()
  tips=()
  low=0
  i=0
  for p in "${paths[@]}"; do
    pct=$(busctl call org.bluez "$p" org.bluez.GattCharacteristic1 ReadValue 'a{sv}' 0 2>/dev/null | awk '{print $3}')
    if [[ ! "$pct" =~ ^[0-9]+$ ]]; then # stale path or disconnected: rediscover next loop
      paths=()
      parts=()
      break
    fi
    l="${LABELS[$i]:-$((i + 1))}"
    parts+=("$l ${pct}%")
    tips+=("$NAME $l: ${pct}%")
    ((pct < LOW)) && low=1
    ((i++))
  done

  if [[ ${#parts[@]} -eq 0 ]]; then
    out='{"text":"","class":"empty"}'
  else
    text="󰌌 $(
      IFS=' · '
      echo "${parts[*]}"
    )"
    tip=$(printf '%s\\n' "${tips[@]}")
    tip=${tip%\\n}
    class=$([[ $low -eq 1 ]] && echo low || echo ok)
    out=$(printf '{"text":"%s","tooltip":"%s","class":"%s"}' "$text" "$tip" "$class")
  fi

  [[ "$out" != "$last" ]] && {
    echo "$out"
    last="$out"
  }
  sleep "$INTERVAL"
done
