if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --color=auto'
  alias ll='eza -lah --group-directories-first --color=auto'
  alias l='eza -la --icons --git --group-directories-first --color=auto'
else
  alias ll='ls -lah'
  alias l='ls -la'
fi

alias sudo='sudo '
alias view="xdg-open"
# alias rm='trash'
alias y='yy'
alias n='nvim'
alias tt='tmux new-session -A -s main'
alias td='sesh connect default'
alias oc="opencode"
alias history='fc -fl 1'
alias hs='history | grep'

alias gf='git fuzzy'
alias gc='git commit -m'
alias gco="git checkout"
alias gs='git status'
alias gc='git commit -m'
alias gca='git commit -am'
alias ga='git add'
alias gaa='git add .'

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


