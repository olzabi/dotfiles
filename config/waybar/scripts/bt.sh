#!/usr/bin/env bash
# One D-Bus call + one jq per run. Hides itself when only $KB_NAME is connected.
busctl --json=short call org.bluez / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null |
  jq -c --arg kb "${KB_NAME:-}" '
  .data[0] as $o
  | ([$o[]["org.bluez.Adapter1"] | select(. != null)] | first) as $a
  | ($a.Powered.data // false) as $on
  | [ $o | to_entries[]
      | select(.value["org.bluez.Device1"].Connected.data == true)
      | { n: (.value["org.bluez.Device1"].Alias.data // .value["org.bluez.Device1"].Name.data // "?"),
          b: (.value["org.bluez.Battery1"].Percentage.data // null) } ] as $devs
  | [ $devs[] | select(($kb == "") or (.n | test($kb; "i") | not)) ] as $others
  | if $a == null then {text:"", class:"empty"}
    elif ($on | not) then {text:"󰂲", tooltip:"Bluetooth off", class:"off"}
    elif ($devs | length) > 0 and ($others | length) == 0 then {text:"", class:"empty"}
    elif ($others | length) > 0 then
      { text: ("󰂱 " + (if ($others | length) == 1
                         then $others[0].n + (if $others[0].b then " \($others[0].b)%" else "" end)
                         else "\($others | length)" end)),
        tooltip: ($others | map(.n + (if .b then "  \(.b)%" else "" end)) | join("\n")),
        class: "connected" }
    else {text:"󰂯", tooltip:"Bluetooth on, no devices", class:"on"}
    end
' || echo '{"text":"","class":"empty"}'
