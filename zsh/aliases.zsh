#!/usr/bin/env zsh

#*
# ---------
alias q=exit
alias quit=exit
alias sudo='sudo '
alias view="explorer.exe"
alias ls='eza --color=always --icons --group-directories-first'
# alias rm='trash'
alias y='yy'
alias n='nvim'
alias zw='zellij --layout layout.kdl'
alias leet='nvim leetcode.nvim'
alias monkey='smassh' # inspired by monkeytype

#* git
# ---------
alias gf='git fuzzy'

alias ld="lazydocker"
alias lg='lazygit'
alias lq='lazysql'

# ---------
alias clearswap="sudo swapoff -a && sudo swapon -a"
alias dirty='watch -n1 "cat /proc/meminfo | grep Dirty"'

# PHP
# ---------
alias serve="artisan serve"
alias tinker="artisan tinker"
alias cu='composer update'
alias ci='composer install'

# TODO:

# Docker
# ---------
# alias dc='docker compose'
# alias dcb='docker compose build'
# alias dcu='docker compose up -d'
# alias dcd='docker compose down'
# alias dockerclean="docker ps -a | grep 'days ago\|weeks ago' | awk '{print $1}' | gxargs --no-run-if-empty docker rm"
# alias dockercleani="docker images | grep '<none>' | awk '{print $3}' | gxargs --no-run-if-empty docker rmi -f"

