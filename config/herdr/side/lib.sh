# Sourced by herdr-side modules (not a module itself: no NN- prefix).
. "$(dirname "${BASH_SOURCE[0]}")/theme.sh"

snapshot() { herdr api snapshot 2>/dev/null | jq '.result.snapshot'; }

# Row helpers: a dim repo sub-header, an italic note (e.g. "no open PRs").
repo_row() { printf 'repo\t%s\t%s%s%s\n' "$1" "$MUTED" "${1##*/}" "$R"; }
info_row() { printf 'info\t\t  %s%s%s%s\n' "$MUTED" "$IT" "$1" "$R"; }

# Main checkout of every repo an agent works in (worktrees collapse onto their repo), one per line.
repos() {
  herdr api snapshot 2>/dev/null | jq -r '.result.snapshot.panes[] | select(.agent != null) | .cwd // empty' |
    while read -r d; do git -C "$d" rev-parse --path-format=absolute --git-common-dir 2>/dev/null; done |
    sort -u | while read -r common; do
      case $common in */.git) dirname "$common" ;; esac # skip bare repos
    done
}

# Shared row actions: o = read in Obsidian (bin/obs), d = lazygit over the herdr window (q returns).
side_open() { setsid -f obs "$@" >/dev/null 2>&1; }
side_changes() {
  [ -d "$1" ] || return 0
  kitty @ launch --type=overlay --next-to 'not var:herdr_side' --cwd "$1" lazygit >/dev/null 2>&1
}
