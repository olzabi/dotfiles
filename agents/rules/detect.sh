#!/bin/sh
# Print the rule files that apply to the repo containing $1 (default: cwd). Shared by Claude and omp hooks.
rules=$(dirname "$(readlink -f "$0")")
dir=$(readlink -f "${1:-.}")
jj= mise=
while [ -n "$dir" ] && [ "$dir" != "$HOME" ] && [ "$dir" != / ]; do
  [ -d "$dir/.jj" ] && jj=1
  for f in mise.toml .mise.toml .config/mise.toml mise/config.toml; do [ -f "$dir/$f" ] && mise=1; done
  dir=${dir%/*}
done
[ -n "$jj" ] && cat "$rules/jj.md"
[ -n "$mise" ] && { [ -n "$jj" ] && echo; cat "$rules/mise.md"; }
# herdr rule: interactive agents only; a headless `claude -p` (plan-loop) must not mark itself ready.
headless() { # the nearest claude ancestor was started with -p/--print
  p=$PPID
  while [ "${p:-1}" -gt 1 ]; do
    if [ "$(cat /proc/$p/comm 2>/dev/null)" = claude ]; then
      case " $(tr '\0' ' ' < /proc/$p/cmdline) " in *" -p "*|*" --print "*) return 0;; *) return 1;; esac
    fi
    p=$(awk '{print $4}' /proc/$p/stat 2>/dev/null)
  done
  return 1
}
[ -n "${HC_TERMINAL_ID:-}" ] && ! headless && { [ -n "$jj$mise" ] && echo; cat "$rules/herdr.md"; }
exit 0
