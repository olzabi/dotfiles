rofi_prompt()  { printf '\0prompt\x1f%s\n' "$1"; }
rofi_message() { printf '\0message\x1f%s\n' "$1"; }
rofi_data()    { printf '\0data\x1f%s\n' "$1"; }
rofi_row()     { printf '%s\0icon\x1f%s\n' "$1" "${2:-}"; }   # label, optional icon

clip()   { wl-paste -n 2>/dev/null || xclip -o -selection clipboard 2>/dev/null; }
detach() { setsid -f "$@" >/dev/null 2>&1; }                  # run and let rofi close
is_url() { [[ $1 =~ ^https?://[^[:space:]]+$ ]]; }
