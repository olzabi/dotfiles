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
exit 0
