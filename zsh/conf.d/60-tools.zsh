# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 60-tools.zsh -- tool hooks (each is skipped if the command isn't installed)

if command -v zoxide >/dev/null 2>&1; then
  _eval zoxide init zsh               # needs compinit to have run (30-plugins)
  alias zz='z -'
fi

_eval starship init zsh
_eval direnv hook zsh               # replaces the OMZ direnv plugin
_eval mise activate zsh
_eval wt config shell init zsh
