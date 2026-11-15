#!/usr/bin/env bash
DL_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}"
URL_RE='^https?://[^[:space:]]+$'
mkdir -p "$DL_DIR"

clip() { wl-paste -n 2>/dev/null || xclip -o -selection clipboard 2>/dev/null; }

# Step 3: format chosen, ROFI_DATA holds the URL -> download
if [[ -n "$ROFI_DATA" ]]; then
  url="$ROFI_DATA"
  case "$1" in
  *Audio*) args=(-x --audio-format mp3 --embed-thumbnail --embed-metadata) ;;
  *1080*) args=(-f "bv*[height<=1080]+ba/b[height<=1080]") ;;
  *720*) args=(-f "bv*[height<=720]+ba/b[height<=720]") ;;
  *) args=(-f "bv*+ba/b") ;;
  esac

  setsid -f bash -c '
    notify-send "yt-dlp" "Downloading…"
    if yt-dlp "$@"; then notify-send "yt-dlp" "Download finished"
    else notify-send -u critical "yt-dlp" "Download failed"; fi
  ' _ -P "$DL_DIR" -o "%(title).150B [%(id)s].%(ext)s" "${args[@]}" "$url" >/dev/null 2>&1
  exit 0
fi

# Step 2: a URL was selected/typed -> choose format
if [[ $1 =~ $URL_RE ]]; then
  printf '\0prompt\x1fFormat\n'
  printf '\0data\x1f%s\n' "$1"
  printf '%s\n' "Video (best)" "Video 1080p" "Video 720p" "Audio (mp3)"
  exit 0
fi

# Step 1: initial screen, offer the clipboard if it holds a URL
printf '\0prompt\x1fURL\n'
printf '\0message\x1fPaste or type a URL, then press Enter\n'
c=$(clip)
[[ $c =~ $URL_RE ]] && printf '%s\n' "$c"
