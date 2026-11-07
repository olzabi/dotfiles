#!/bin/sh
# SessionStart: inject jj/mise rules only when the session's repo uses them (stdout becomes context).
cwd=$(jq -r '.cwd // empty' 2>/dev/null)
exec "$HOME/Dotfiles/agents/rules/detect.sh" "${cwd:-$PWD}"
