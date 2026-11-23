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

if command -v claude >/dev/null 2>&1; then
  alias cc="claude"
fi

if command -v mise >/dev/null 2>&1; then
  misei() {
    MISE_MINIMUM_RELEASE_AGE=0 mise install "$@"
  }

  # Install and activate globally in one go
  miseig() {
    MISE_MINIMUM_RELEASE_AGE=0 mise use -g "$@"
  }
  alias m="mise"
  alias mi="misei"
  alias mug="miseig"
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
alias nt='NVIM_TRY=all nvim' # nvim + trial plugins (config/nvim/lua/try); NVIM_TRY=flash,harpoon for some
alias tt='tmux new-session -A -s main'
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
	alias gr="git rebase -i"
	alias gs="git status -sb"
	alias gt="git tag"
	alias gu="git reset @ --" #think git unstage
	alias gx="git reset --hard @"
fi

if (( $+commands[gh] )); then
    # --- Pull requests ---
  alias ghpc='gh pr create'
  alias ghpcf='gh pr create --fill'          # use commit info for title/body
  alias ghpcd='gh pr create --draft --fill'
  alias ghpl='gh pr list'
  alias ghpm='gh pr list --author "@me"'     # my PRs
  alias ghpv='gh pr view'
  alias ghpw='gh pr view --web'
  alias ghpco='gh pr checkout'
  alias ghpd='gh pr diff'
  alias ghpch='gh pr checks'
  alias ghpr='gh pr ready'
  alias ghpmg='gh pr merge --squash --delete-branch'
  alias ghprv='gh pr review'
  alias ghpa='gh pr review --approve'
  # --- Issues ---
  alias ghic='gh issue create'
  alias ghil='gh issue list'
  alias ghim='gh issue list --assignee "@me"'
  alias ghiv='gh issue view'
  alias ghiw='gh issue view --web'
  alias ghicl='gh issue close'
  # --- Repos ---
  alias ghrv='gh repo view'
  alias ghrw='gh repo view --web'
  alias ghrc='gh repo clone'
  alias ghrf='gh repo fork --clone'
  alias ghrn='gh repo create'
  # --- Actions / workflows ---
  alias ghrl='gh run list'
  alias ghrwt='gh run watch'
  alias ghrvw='gh run view'
  alias ghrrf='gh run rerun --failed'
  alias ghwl='gh workflow list'
  # --- Misc ---
  alias ghs='gh status'
  alias ghb='gh browse'
  alias ghg='gh gist create'
  alias ghrel='gh release list'
fi

if (( $+commands[lazygit] )); then
  lg() {
    local f=~/.cache/lazygit-newdir
    LAZYGIT_NEW_DIR_FILE=$f lazygit "$@"
    [[ -f $f ]] && cd "$(<$f)" && rm -f "$f"
  }
fi

alias ld="lazydocker"
alias lq='lazysql'
alias la='lazyactions'
alias lr='posting'

# ---

alias d='dirs -v | head -n 10'
alias q=exit
alias md='mkdir -p'

alias dirty='watch -n1 "cat /proc/meminfo | grep Dirty"'

alias uvpi="uv pip install"
