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
	artisan
	composer
	branch
	docker
	docker-compose
	direnv
	encode64
	eza
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
	zsh-autosuggestions
	zsh-completions
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
	ng
	nestjs
)

export RUSTFLAGS="-C opt-level=3 -C target-cpu=native" # Rust app build optimization

# ---------
#`FZF_DEFAULT_OPTS_FILE`
export FZF_DEFAULT_COMMAND='rg --files' # Include hidden files
export FZF_DEFAULT_OPTS=" \
  --layout=reverse --border top \
  --bind=ctrl-space:accept"

export FZF_CTRL_T_OPTS="
  --preview 'cat -n --color=always {}'
  --reverse
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# ---------
. "$XDG_LOCAL_HOME/bin/env"
. "$ZSH/oh-my-zsh.sh"

[ -f "$ZSH/../aliases.zsh" ] && source "$ZSH/../aliases.zsh"

[ -x "$(command -v zoxide)" ] && eval "$(zoxide init zsh)"
[ -x "$(command -v phpenv)" ] && eval "$(phpenv init -)"
[ -x "$(command -v pyenv)" ]  && eval "$(pyenv init - zsh)"

