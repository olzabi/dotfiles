#!/usr/bin/env zsh

ZSH_THEME="eternity" # "starlight"|"mh"

HIST_STAMPS="mm/dd/yyyy"
ENABLE_CORRECTION=false
DISABLE_LS_COLORS=true
ZSH_DOTENV_PROMPT=false
HISTSIZE=100000
HISTFILESIEZE=10000

zstyle ':omz:update' mode auto # update automatically without asking
zstyle ':omz:plugins:ssh-agent' agent-forwarding on
zstyle ':completion:*' rehash true

zstyle ':omz:plugins:nvm' autoload yes

plugins=(
	aws
	branch
	docker
	docker-compose
	encode64
	sudo
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
	last-working-dir
	man
	nmap
	npm
	nvm
	nodenv
	yarn
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
	zsh-autosuggestions
	zsh-syntax-highlighting
	fancy-ctrl-z
	python
	pip
	pipenv
	virtualenv
	postgres
	laravel
	jsontools
	golang

)

export RUSTFLAGS="-C opt-level=3 -C target-cpu=native" # Rust app build optimization

. "$ZSH/oh-my-zsh.sh"

[ -f "$ZSH/../aliases.zsh" ] && source "$ZSH/../aliases.zsh"

eval "$(phpenv init -)"
eval "$(pyenv init - zsh)"
