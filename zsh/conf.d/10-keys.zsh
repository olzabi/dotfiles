# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 10-keys.zsh -- keymap and keybindings (must load before the plugins)

# OMZ's lib/key-bindings.zsh ran `bindkey -e`, which silently overrode your old
# `set -o vi`. This keeps the mode you actually had. For vi mode use `bindkey -v`.
bindkey -e

zmodload zsh/terminfo
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
  zle-line-init()   { echoti smkx }
  zle-line-finish() { echoti rmkx }
  zle -N zle-line-init
  zle -N zle-line-finish
fi

autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

for _m in emacs viins vicmd; do
  [[ -n $terminfo[khome] ]] && bindkey -M $_m $terminfo[khome] beginning-of-line
  [[ -n $terminfo[kend]  ]] && bindkey -M $_m $terminfo[kend]  end-of-line
  [[ -n $terminfo[kdch1] ]] && bindkey -M $_m $terminfo[kdch1] delete-char
  [[ -n $terminfo[kcbt]  ]] && bindkey -M $_m $terminfo[kcbt]  reverse-menu-complete
  [[ -n $terminfo[kcuu1] ]] && bindkey -M $_m $terminfo[kcuu1] up-line-or-beginning-search
  [[ -n $terminfo[kcud1] ]] && bindkey -M $_m $terminfo[kcud1] down-line-or-beginning-search
  bindkey -M $_m '^[[A'    up-line-or-beginning-search
  bindkey -M $_m '^[[B'    down-line-or-beginning-search
  bindkey -M $_m '^[[1;5C' forward-word
  bindkey -M $_m '^[[1;5D' backward-word
  bindkey -M $_m '^[[3;3~' kill-word            # yours, now in every keymap
  bindkey -M $_m '^[^?'    backward-kill-word   # yours, now in every keymap
done
unset _m
