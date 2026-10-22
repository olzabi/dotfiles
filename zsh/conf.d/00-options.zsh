# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 00-options.zsh -- paths, environment, history, shell options, helpers

# --- Paths -----------------------------------------------------------------
# $ZSHCONF (set in zshrc) is this dotfiles/zsh directory. aliases.zsh,
# functions.zsh and fzf.zsh live next to it. Drop the old ZSH export (it pointed
# at the oh-my-zsh checkout); use-omz points $ZSH at antidote's own clone.
unset ZSH

ANTIDOTE_DIR=$XDG_DATA_HOME/antidote   # per-machine install, not part of the repo

export MANPAGER='nvim +Man!'
export MANPATH="/usr/local/man:$MANPATH"
export RUSTFLAGS="-C opt-level=3 -C target-cpu=native" # Rust app build optimization

HISTSIZE=110000
SAVEHIST=100000
FUNCNEST=500

setopt append_history extended_history
setopt hist_find_no_dups hist_reduce_blanks hist_expire_dups_first hist_ignore_dups
setopt hist_ignore_space hist_verify inc_append_history share_history

# --- Shell options ---------------------------------------------------------
setopt glob_dots
setopt no_case_glob
setopt numeric_glob_sort
setopt rc_expand_param
setopt correct_all

# Things OMZ's lib/ used to turn on
setopt pushd_ignore_dups interactive_comments auto_cd auto_pushd pushd_minus multios long_list_jobs prompt_subst
setopt auto_menu complete_in_word always_to_end
unsetopt menu_complete flow_control

# --- Helpers (used by later files) -----------------------------------------
# Run `<cmd> <args>` and eval its output, only if <cmd> exists and succeeds.
_eval() {
  local c=$1 out; shift
  (( $+commands[$c] )) || return 0
  out=$($c "$@") || return
  eval "$out"
}
