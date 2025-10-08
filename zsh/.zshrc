#!/usr/bin/env zsh

ZSH_THEME="starlight"
# ZSH_THEME="mh"

HIST_STAMPS="mm/dd/yyyy"
ENABLE_CORRECTION=false
DISABLE_LS_COLORS=true
ZSH_DOTENV_PROMPT=false

HISTSIZE=100000
HISTFILESIEZE=10000

zstyle ':omz:update' mode auto # update automatically without asking
zstyle ':omz:plugins:ssh-agent' agent-forwarding on

zstyle ':completion:*' rehash true

plugins=(
	aws
	branch
	# chezmoi
	# direnv
	docker
	encode64
	fancy-ctrl-z
	fzf
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
	# last-working-dir
	man
	nmap
	npm
	nvm
	rust
	ssh-agent
	tldr
	terraform
	vscode
	you-should-use
	zsh-autosuggestions
	zsh-syntax-highlighting
)

# Rust app build optimization
# ----------------------------------------------------------------------
export RUSTFLAGS="-C opt-level=3 -C target-cpu=native"

#* nvm
# ----------------------------------------------------------------------
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# adds hook to change node version upon switching dir, if .nvmrc exists in project dir
autoload -U add-zsh-hook
load-nvmrc() {
  [[ -a .nvmrc ]] || return
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Source nix-daemon environment if it exists
# ----------------------------------------------------------------------
# if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
#   . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
# fi

#* zsh custom loads
# ----------------------------------------------------------------------
[ -f "$ZSH/../aliases.zsh" ] && source "$ZSH/../aliases.zsh"
# [ -f "$ZSH/custom.zsh" ] && source "$ZSH/custom.zsh"

#* zsh init
# ----------------------------------------------------------------------
source "$ZSH/oh-my-zsh.sh"

#* zellij
# eval "$(zellij setup --generate-auto-start zsh)"
# --bind=ctrl-j:abort \

eval "$(phpenv init -)"
eval "$(pyenv init - zsh)"

source <(fzf --zsh)
