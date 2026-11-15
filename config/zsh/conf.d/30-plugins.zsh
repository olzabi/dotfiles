typeset -gU fpath
fpath=($XDG_CACHE_HOME/zsh/site-functions $fpath) # is necessary for mise `mise completion zsh --install`
fpath=(/usr/share/zsh/site-functions $fpath)

. /usr/share/zsh-antidote/antidote.zsh # pacman zsh-antidote
antidote load $ZSHCONF/plugins.txt $XDG_CACHE_HOME/zsh/plugins.zsh

if (( $+functions[run-compinit] )); then
  run-compinit
else
  autoload -Uz compinit && compinit -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

# Phase 2: must come AFTER compinit, and fzf before fzf-tab (replaces OMZ's fzf plugin)
_eval fzf --zsh
antidote load $ZSHCONF/plugins-late.txt $XDG_CACHE_HOME/zsh/plugins-late.zsh   # fzf-tab, zsh-autopair, you-should-use
