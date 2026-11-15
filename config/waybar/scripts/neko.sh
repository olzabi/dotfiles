#!/usr/bin/env bash
# Text oneko for Waybar: a cat that wanders a small track, sits, grooms, sleeps.
# Streams one JSON line per frame. Click (SIGUSR1) pets it.
W=${NEKO_WIDTH:-24}
cat=$'\U000F011B' paw=$'\U000F03E9' zz=$'\U000F04B2' heart=$'\U000F02D1'
x=$((RANDOM % W)) dir=1 state=walk left=$((20 + RANDOM % 30)) idle=0 pet=0
trap 'pet=12' USR1

frame() { # $1 = glyph(s) drawn at x
  local pad="" i
  for ((i = 0; i < x; i++)); do pad+=$' '; done
  local s="$pad$1"
  while ((${#s} < W + 2)); do s+=$' '; done
  printf '{"text":"%s","class":"%s","tooltip":"neko is %s"}\n' "$s" "$2" "$2"
}

while :; do
  if ((pet > 0)); then
    ((pet--)); idle=0; state=sit; left=10
    frame "$cat$heart" petted
  else
    case $state in
      walk)
        ((RANDOM % 15 == 0)) && dir=$((-dir))
        ((x += dir))
        # clamp: toggling at the edge let a random flip push x past W forever
        ((x <= 0)) && { x=0; dir=1; }
        ((x >= W - 1)) && { x=$((W - 1)); dir=-1; }
        frame "$cat" walking ;;
      sit) frame "$cat" sitting ;;
      groom) ((left % 4 < 2)) && frame "$cat$paw" grooming || frame "$cat" grooming ;;
      sleep) ((left % 10 < 5)) && frame "$cat$zz" sleeping || frame "$cat " sleeping ;;
    esac
    if ((--left <= 0)); then
      ((idle++))
      if [[ $state == sleep ]] || ((idle > 6 && RANDOM % 2)); then
        [[ $state == sleep ]] && { state=walk; idle=0; left=$((20 + RANDOM % 40)); } \
          || { state=sleep; left=$((150 + RANDOM % 300)); }
      else
        states=(walk walk sit groom)
        state=${states[RANDOM % 4]}
        left=$((10 + RANDOM % 30))
      fi
    fi
  fi
  sleep ${NEKO_TICK:-0.2} & wait $!   # wait lets the USR1 trap fire immediately
done
