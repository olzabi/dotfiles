#!/usr/bin/env bash
if [ -z "$1" ]; then
    # show only the text; the "id<TAB>" prefix stays in the row so decode still works
    cliphist list | while IFS= read -r line; do
        printf '%s\0display\x1f%s\n' "$line" "${line#*$'\t'}"
    done
else
    cliphist decode <<< "$1" | wl-copy
fi
