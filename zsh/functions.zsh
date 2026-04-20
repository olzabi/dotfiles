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
yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function yap() {
    local yaziProject="$1"
    shift
    if [ -z "$yaziProject" ]; then
        >&2 echo "ERROR: The first argument must be a project"
        return 64
    fi

    # Generate random Yazi client ID (DDS / `ya emit` uses `YAZI_ID`)
    local yaziId=$RANDOM

    # Use Yazi's DDS to run a plugin command after Yazi has started
    # (the nested subshell is only to suppress "Done" output for the job)
    ( (sleep 0.1; YAZI_ID=$yaziId ya emit plugin projects "load $yaziProject") &)

    y --client-id $yaziId "$@" || return $?
}

# Go test and show coverage
# ---------
gotest() {
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

gotestcov() {
	go list ./... | grep --color=auto --color=never $1 | xargs go test -v -race -coverprofile=profile.out -covermode=atomic
	local exitCode=$?
	if [ -f profile.out ]; then
		go tool cover -func=profile.out
		go tool cover -html=profile.out
		rm profile.out
	fi
	return $exitCode
}

gobench() {
	local foo=${1:-.}
	go test -bench=${foo} -benchmem ./... 2>/dev/null | grep Benchmark | column -t
}

# ---
meme() {
	yt-dlp "$1" -o "/mnt/d/ayaya/%(title)s.%(ext)s"
}

bak() {
	for file in "$@"; do
		cp "$file" "$file".bak
	done
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



