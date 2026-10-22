#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
  jq -cn '{text:"", tooltip:"NVIDIA GPU telemetry is unavailable", class:"unavailable"}'
  exit 0
fi

query=$(nvidia-smi \
  --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
  --format=csv,noheader,nounits 2>/dev/null) || query=""

if [[ -z "$query" ]]; then
  jq -cn '{text:"", tooltip:"NVIDIA GPU telemetry is unavailable", class:"unavailable"}'
  exit 0
fi

row=${query%%$'\n'*}
IFS=',' read -r name utilization memory_used memory_total temperature <<< "$row"

trim() {
  local value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s' "$value"
}

name=$(trim "${name:-NVIDIA GPU}")
utilization=$(trim "${utilization:-N/A}")
memory_used=$(trim "${memory_used:-N/A}")
memory_total=$(trim "${memory_total:-N/A}")
temperature=$(trim "${temperature:-N/A}")

text="󰢮 ${utilization}%"
if [[ "$temperature" =~ ^[0-9]+$ ]]; then
  text+=" ${temperature}°"
fi

tooltip=$(printf '%s\nGPU utilization: %s%%\nVRAM: %s / %s MiB\nTemperature: %s°C' "$name" "$utilization" "$memory_used" "$memory_total" "$temperature")

jq -cn \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  '{text: $text, tooltip: $tooltip, class: "gpu"}'
