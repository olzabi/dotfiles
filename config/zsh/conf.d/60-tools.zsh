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

# gw2-alt (bin/gw2-alt): complete account names from the saved logins, or the running ones for -x/-d
_gw2_alt() {
  local data=${GW2_ALT_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/gw2alts}
  local run=${GW2_ALT_RUNTIME_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/gw2alts}
  if (( CURRENT == 2 )) && [[ $PREFIX == -* ]]; then
    _describe option '(-o:"set up an account" -u:"update after a patch" -x:"close accounts" -d:"clean up a stuck mount" -h:help)'
  elif [[ ${words[2]} == -[xd] ]]; then
    local mounts=($run/*(N/:t)); local -U names=($run/*.pid(N:t:r) ${mounts:#(upper|work)-*})
    compadd -- $names
  else
    [[ ${words[2]} == -o ]] && (( CURRENT > 3 )) && return # -o takes one
    compadd -- $data/*.dat(N:t:r)
  fi
}
compdef _gw2_alt gw2-alt
