
function disks() {
	# echo
	function _e() {
		title=$(echo "$1" | sed 's/./& /g')
		echo "
\033[0;31m╓─────\033[0;35m ${title}
\033[0;31m╙────────────────────────────────────── ─ ─"
	}
	# loops
	function _l() {
		X=$(printf '\033[0m')
		G=$(printf '\033[0;32m')
		R=$(printf '\033[0;35m')
		C=$(printf '\033[0;36m')
		W=$(printf '\033[0;37m')
		i=0;
		while IFS= read -r line || [[ -n $line ]]; do
			if [[ $i == 0 ]]; then
				echo "${G}${line}${X}"
			else
				if [[ "$line" == *"%"* ]]; then
					percent=$(echo "$line" | awk '{ print $5 }' | sed 's!%!!')
					color=$W
					((percent >= 75)) && color=$C
					((percent >= 90)) && color=$R
					line=$(echo "$line" | sed "s/${percent}%/${color}${percent}%${W}/")
				fi
				echo "${W}${line}${X}" | sed "s/\([─└├┌┐└┘├┤┬┴┼]\)/${R}\1${W}/g; s! \(/.*\)! ${C}\1${W}!g;"
			fi
			i=$((i+1))
		done < <(printf '%s' "$1")
	}
	# outputs
	m=$(lsblk -a | grep -v loop)
	_e "mount.points"
	_l "$m"
	d=$(df -h)
	_e "disk.usage"
	_l "$d"
	s=$(swapon --show)
	_e "swaps"
	_l "$s"
}

function nmap() {
	if [[ -z "$*" ]]; then
		scan=$(printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s" \
			"'-sS' TCP SYN scan (best option)" \
			"'-sT' full TCP connect scan" \
			"'-sU' scan UDP ports" \
			"'-sn' ping scan" \
			"'-sP' ping scan only" \
			"'-Pn' do not ping the hosts, assume they are up" \
			"'-PE' ICMP Echo Request" \
			"'-sV' version detection scan of open ports / services" \
			"'-0'  identify Operating System version" \
			"'-A'  this combines OS detection, service version detection, script scanning and traceroute" \
			"'-sn' probe only (host discovery, not port scan)" \
				| fzf --height=50% --border --color=label:italic:#87FFAF --border-label='[ nmap scan type ]' | sed "s/' .*$//;s/'//g")
		[[ "$scan" == "" ]] && return 1
		output=$(printf "%s\n%s\n%s\n%s\n%s" \
			"raw" \
			"'-oN' normal text format" \
			"'-oG' grepable file" \
			"'-oX' XML file" \
			"'-oA' output in all 3 formats supported" \
				| fzf --height=50% --border --color=label:italic:#87FFAF --border-label='[ nmap output ]' | sed "s/' .*$//;s/'//g")
		[[ "$output" == "" ]] && return 1
		if [[ "$output" != "raw" ]]; then
			vared -p 'filename: ' -c file
		else
			output=""
		fi
		probe=$(printf "%s\n%s\n%s\n%s\n%s" \
			"'-Pn' do not probe (assume all hosts are up)" \
			"'-PB' default probe (TCP 80, 445 & ICMP)" \
			"'-PS' discrete TCP ports" \
			"'-PP' ICMP Timestamp Request" \
			"'-PM' ICMP Netmask Request" \
				| fzf --height=50% --border --color=label:italic:#87FFAF --border-label='[ nmap probing ]' | sed "s/' .*$//;s/'//g")
		[[ "$probe" == "" ]] && return 1
		if [[ "$probe" == "-PS" ]]; then
			vared -p 'ports to scan: ' -c ports
			[[ "$ports" == *" "* && ! "$ports" == *","* ]] && \
				ports=${ports// /,}
		fi
		speed=$(printf "%s\n%s\n%s\n%s\n%s\n%s" \
			"'-T0' Paranoid: Very slow, used for IDS evasion" \
			"'-T1' Sneaky: Quite slow, used for IDS evasion" \
			"'-T2' Polite: Slows down to consume less bandwidth, runs ~10 times slower than default" \
			"'-T3' Normal: Default, a dynamic timing model based on target responsiveness" \
			"'-T4' Aggressive: Assumes a fast and reliable network and may overwhelm targets" \
			"'-T5' Insane: Very aggressive; will likely overwhelm targets or miss open ports" \
				| fzf --height=50% --border --color=label:italic:#87FFAF --border-label='[ nmap speed ]' | sed "s/' .*$//;s/'//g")

		if [[ -z "$ports" ]]; then
			p=$(printf "%s\n%s\n%s\n%s" \
				"single" "range" "list" "all" \
				| fzf --height=50% --border --color=label:italic:#87FFAF --border-label='[ nmap port ]' | sed "s/' .*$//;s/'//g")
			case "$p" in
				single) m="80" ;;
				range) m="23-25" ;;
				list) m="80,443" ;;
			esac
			if [[ "$p" == "all" ]]; then
				ports=" -p-"
			else
				vared -p "ports to scan [e.g. $m]: " -c ports
				ports=" -p$ports"
			fi
		fi
		echo "nmap $speed $scan $probe $ports $output $file $targets"
	else
		/usr/bin/nmap "$@"
	fi
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



