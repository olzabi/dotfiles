#!/usr/bin/env zsh

ZSH_THEME=""

HIST_STAMPS="mm/dd/yyyy"
ENABLE_CORRECTION=false
DISABLE_LS_COLORS=true
ZSH_DOTENV_PROMPT=false
HISTSIZE=100000
HISTFILESIZE=10000
SAVEHIST=10000
FUNCNEST=500

set -o vi
export MANPAGER='nvim +Man!'
export MANPATH="/usr/local/man:$MANPATH"

setopt glob_dots
setopt no_case_glob
setopt numeric_glob_sort
setopt rc_expand_param
setopt interactive_comments
setopt correct_all
setopt pushd_ignore_dups
setopt auto_cd

setopt append_history
setopt extended_history
setopt hist_find_no_dups
setopt hist_reduce_blanks
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history

zstyle ':omz:update' mode auto

zstyle ':completion:*' rehash true
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false

zstyle ':fzf-tab:*' fzf-flags --color=bg:#1c1c1c,bg+:#303030,fg:#c0c0c0,fg+:#f1f1f1,hl:#1bfd9c,hl+:#bdfe58,prompt:#1bfd9c,pointer:#bdfe58,marker:#1bfd9c,border:#585858,label:#585858,info:#585858
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza --tree --level=2 --color=always $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'cat --color=always --style=numbers $realpath 2>/dev/null || eza --tree --color=always $realpath'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-header -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:export:argument-1' fzf-preview 'printenv $word'

zstyle ':omz:plugins:ssh-agent' agent-forwarding on
zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes

plugins=(
  aws
  artisan
  composer
  # colemak
  branch
  docker
  docker-compose
  dotenv
  direnv
  encode64
  eza
  fancy-ctrl-z
  fzf
  fzf-tab
  gh
  git-auto-fetch
  git-escape-magic
  git-extras
  gitfast
  gitignore
  golang
  kubectl
  kubectx
  last-working-dir
  laravel
  man
  nmap
  npm
  nvm
  ng
  nestjs
  # yarn
  ssh
  ssh-agent
  sudo
  tldr
  terraform
  tmux
  tmuxinator
  redis-cli
  react-native
  rust
  ubuntu
  python
  pip
  pipenv
  uv
  vault
  virtualenv
  vi-mode
  jsontools
  you-should-use
  zsh-autosuggestions
  zsh-autopair
  zsh-completions
  zsh-syntax-highlighting
)

export RUSTFLAGS="-C opt-level=3 -C target-cpu=native" # Rust app build optimization
export RUST_SRC_PATH="${RUST_SRC_PATH:-$(rustc --print sysroot 2>/dev/null)/lib/rustlib/src/rust/src}"
# ---------

. "$ZSH/oh-my-zsh.sh"
. "$ZSH/../aliases.zsh"
. "$ZSH/../functions.zsh"
. "$ZSH/../fzf.zsh"
. "$ZSH/../llm.zsh"

_eval() { local c=$1; shift; (( $+commands[$c] )) && eval "$($c "$@")" }

_eval starship init zsh

_eval zoxide init zsh
_eval phpenv init -
_eval pyenv  init - zsh
_eval rbenv  init -
_eval gh     enhance completion zsh

export NVM_DIR="$DOTFILES_TOOLS/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# PATH dedup
PATH=$(printf %s "$PATH" | awk -v RS=: -v ORS=: '!seen[$0]++' | sed 's/:$//')
