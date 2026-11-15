#!/usr/bin/env bash
set -euo pipefail

cpu_ticks() {
  awk '
    /^cpu / {
      total = 0
      for (i = 2; i <= 9; i++) total += $i
      idle = $5 + $6
      printf "%.0f %.0f\n", total, idle
      exit
    }
  ' /proc/stat
}

read -r total_before idle_before < <(cpu_ticks)
sleep 0.2
read -r total_after idle_after < <(cpu_ticks)

cpu_usage=$(awk \
  -v before_total="$total_before" -v before_idle="$idle_before" \
  -v after_total="$total_after" -v after_idle="$idle_after" \
  'BEGIN {
    total_delta = after_total - before_total
    idle_delta = after_idle - before_idle
    usage = total_delta > 0 ? 100 * (total_delta - idle_delta) / total_delta : 0
    if (usage < 0) usage = 0
    if (usage > 100) usage = 100
    printf "%.0f", usage
  }')

read -r ram_used ram_total ram_percent < <(awk '
  /^MemTotal:/ { total = $2 }
  /^MemAvailable:/ { available = $2 }
  END {
    if (total > 0) {
      used = total - available
      printf "%.1f %.1f %.0f\n", used / 1048576, total / 1048576, 100 * used / total
    }
  }
' /proc/meminfo)

jq -cn \
  --arg cpu "$cpu_usage" \
  --arg ram "$ram_percent" \
  --arg used "$ram_used" \
  --arg total "$ram_total" \
  '{
    text: (" " + $cpu + "%   " + $ram + "%"),
    tooltip: ("CPU: " + $cpu + "%\nRAM: " + $used + " / " + $total + " GiB (" + $ram + "%)"),
    class: "system"
  }'
