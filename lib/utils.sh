#!/bin/bash

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
RESET="\033[0m"

info()    { echo -e "${BOLD}$*${RESET}"; }
success() { echo -e "${GREEN}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error()   { echo -e "${RED}❌ $*${RESET}" >&2; exit 1; }

expand_conf() {
  local file="$1" line name pair key val
  declare -A groups=()

  while IFS= read -r line || [ -n "$line" ]; do
    if [[ "$line" == @*[[:space:]]* ]]; then
      name="${line%% *}"; name="${name#@}"
      groups["$name"]="${line#* }"
      continue
    fi
    if [[ -z "$line" || "$line" == \#* ]]; then
      echo "$line"
      continue
    fi
    name=""
    for key in "${!groups[@]}"; do
      [[ "$line" == *"@$key"* ]] && { name="$key"; break; }
    done
    if [[ -n "$name" ]]; then
      for pair in ${groups[$name]}; do
        val="${pair#*=}"
        echo "${line//@$name/$val}"
      done
    else
      echo "$line"
    fi
  done <"$file"
}
