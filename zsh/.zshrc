#!/usr/bin/env zsh

ZSH_THEME="eternity" # "starlight"|"mh"

HIST_STAMPS="mm/dd/yyyy"
ENABLE_CORRECTION=false
DISABLE_LS_COLORS=true
ZSH_DOTENV_PROMPT=false
HISTSIZE=100000
HISTFILESIEZE=10000
FUNCNEST=500

setopt append_history
setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_dups # ignore duplication command history list
setopt hist_ignore_space
setopt hist_verify
setopt inc_append_history
setopt share_history # share command history data

zstyle ':omz:update' mode auto # update automatically without asking
zstyle ':omz:plugins:ssh-agent' agent-forwarding on
zstyle ':completion:*' rehash true

zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes

plugins=(
  aws
  artisan
  composer
  branch
  docker
  docker-compose
  dotenv
  direnv
  encode64
  eza
  sudo
  fzf
  zsh-autosuggestions
  fzf-tab
  gh
  git
  git-auto-fetch
  git-commit
  git-escape-magic
  git-extras
  gitfast
  gitignore
  history
  kubectl
  kubectx
  last-working-dir
  man
  nmap
  npm
  nvm
  nodenv
  # yarn
  rust
  ssh
  ssh-agent
  tldr
  terraform
  vault
  redis-cli
  react-native
  qrcode
  you-should-use
  zsh-completions
  fancy-ctrl-z
  python
  pip
  pipenv
  virtualenv
  postgres
  laravel
  jsontools
  golang
  ng
  nestjs
  zsh-syntax-highlighting
)

export RUSTFLAGS="-C opt-level=3 -C target-cpu=native" # Rust app build optimization
# ---------

. "$ZSH/oh-my-zsh.sh"
#. "$XDG_LOCAL_HOME/bin/env"
. "$ZSH/../aliases.zsh"
. "$ZSH/../functions.zsh"
. "$ZSH/../fzf.zsh"
. "$ZSH/../llm.zsh"

[ -x "$(command -v zoxide)" ] && eval "$(zoxide init zsh)"
[ -x "$(command -v phpenv)" ] && eval "$(phpenv init -)"
[ -x "$(command -v pyenv)" ] && eval "$(pyenv init - zsh)"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
