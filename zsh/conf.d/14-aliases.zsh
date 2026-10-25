if command -v bat >/dev/null; then
    alias cat='bat --paging=never'
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --color=auto'
  alias ll='eza -lah --group-directories-first --color=auto'
  alias l='eza -la --icons --git --group-directories-first --color=auto'
else
  alias ll='ls -lah'
  alias l='ls -la'
fi

alias -- -='cd -'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'


alias sudo='sudo '
alias view="xdg-open"
# alias rm='trash'
alias rmrf="rm -rf"
alias y='yy'
alias n='nvim'
alias tt='tmux new-session -A -s main'
alias td='sesh connect default'
alias oc="opencode"
alias history='fc -fl 1'
alias hs='history | grep'

if (( $+commands[git] )); then
	alias ga="git add"
	alias gb="git branch"
	alias gc="git clone"
	alias gcm="git commit -m"
	alias gco="git checkout"
	alias gcob="git checkout -b"
	alias gcs="git commit -S -m"
	alias gd="git difftool"
	alias gdc="git difftool --cached"
	alias gf="git fetch"
	alias gg="git graph"
	alias ggg="git graphgpg"
	alias gm="git merge"
	alias gp="git push"
	alias gpr="gh pr create"
	alias gr="git rebase -i"
	alias gs="git status -sb"
	alias gt="git tag"
	alias gu="git reset @ --" #think git unstage
	alias gx="git reset --hard @"
fi

alias ld="lazydocker"
alias lg='lazygit'
alias lq='lazysql'
alias la='lazyactions'
alias lr='posting'

# ---

alias d='dirs -v | head -n 10'
alias q=exit
alias -g ...='../..'
alias -g ....='../../..'
alias md='mkdir -p'


