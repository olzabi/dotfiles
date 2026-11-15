# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 60-tools.zsh -- tool hooks (each is skipped if the command isn't installed)

_eval mise activate zsh # first, so the inits below run real binaries instead of shims

if command -v zoxide >/dev/null 2>&1; then
  _eval zoxide init --cmd cd zsh
fi

_eval starship init zsh
_eval direnv hook zsh
_eval wt config shell init zsh
_eval tv init zsh # its ctrl-r is taken over by atuin below
(( $+widgets[tv-smart-autocomplete] )) && bindkey '^[t' tv-smart-autocomplete # alt-t: herdr-app owns ctrl-t (tab.new)
_eval atuin init zsh --disable-up-arrow # after fzf --zsh so atuin owns ctrl-r; up-arrow stays prefix search (10-keys.zsh)

# ctrl-o: yazi in the current dir; quitting with `q` cds the shell to where yazi was (yy in 17-functions.zsh)
_yazi_widget() { zle -I; yy </dev/tty; zle reset-prompt; }
zle -N _yazi_widget
bindkey '^O' _yazi_widget
