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

function meme() {
	yt-dlp "$1" -o "/mnt/d/ayaya/%(title)s.%(ext)s"
}

bak() {
	for file in "$@"; do
		cp "$file" "$file".bak
	done
}

# Go test and show coverage
# ---------
function gotest() {
	if [ -z $1 ]; then
		go test -cover ./...
	elif [ $1 = "-t" ]; then
		go test -cover ./... | column -t
	elif [ $1 = "." ]; then
		go test -v -race -coverprofile=profile.out -covermode=atomic
	elif [ $1 = "./..." ]; then
		echo 'mode: atomic' >profile.out
		go list ./... | xargs -I {} sh -c "go test -v -race -coverprofile=profile.out.tmp -covermode=atomic {}; cat profile.out.tmp | tail -n +2 >> profile.out; rm profile.out.tmp"
	else
		go list ./... | grep --color=auto --color=auto --color=never $1 | xargs go test -v -race -coverprofile=profile.out -covermode=atomic
	fi
	local exitCode=$?
	if [ -f profile.out ]; then
		go tool cover -func=profile.out
		rm profile.out
	fi
	return $exitCode
}

function gotestcov() {
	go list ./... | grep --color=auto --color=never $1 | xargs go test -v -race -coverprofile=profile.out -covermode=atomic
	local exitCode=$?
	if [ -f profile.out ]; then
		go tool cover -func=profile.out
		go tool cover -html=profile.out
		rm profile.out
	fi
	return $exitCode
}

function gobench() {
	local foo=${1:-.}
	go test -bench=${foo} -benchmem ./... 2>/dev/null | grep Benchmark | column -t
}

#* git tag remove
# ---------
gtrm() {
	git tag -d $1

	if [ ! -z "$2" ]; then
		git push $2 :refs/tags/$1
	else
		git push origin :refs/tags/$1
	fi
}

#* yazi
# ---------
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function note() {
	if [[ -z $1 ]]; then
		$EDITOR $NOTES_PATH/notes/$1
	else
		$EDITOR $NOTES_PATH/notes/$(date "+%D")
	fi
}

kill_port() {
  if [ -z "$1" ]; then
    echo "Usage: kill_port <port_number>"
    return 1
  fi

  PORT=$1
  PID=$(lsof -ti tcp:$PORT)

  if [ -z "$PID" ]; then
    echo "No process found running on port $PORT."
    return 1
  fi

  echo "Killing process $PID on port $PORT..."
  kill -9 $PID && echo "Killed."
}

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

