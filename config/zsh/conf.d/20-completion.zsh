# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 20-completion.zsh -- completion styles (just zstyles; compinit runs in 30-plugins)

zstyle ':omz:update' mode disabled   # still read by use-omz's update check

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' rehash true
zstyle ':completion:*' menu no
zstyle ':completion:*' use-cache yes
mkdir -p "$XDG_CACHE_HOME/zsh/compcache"
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/compcache"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false

zstyle ':fzf-tab:*' fzf-flags --color=bg:#1c1c1c,bg+:#303030,fg:#c0c0c0,fg+:#f1f1f1,hl:#1bfd9c,hl+:#bdfe58,prompt:#1bfd9c,pointer:#bdfe58,marker:#1bfd9c,border:#585858,label:#585858,info:#585858
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --level=2 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*'  fzf-preview 'eza --tree --level=2 --color=always $realpath'
zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'cat --color=always --style=numbers $realpath 2>/dev/null || eza --tree --color=always $realpath'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-header -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:export:argument-1' fzf-preview 'printenv $word'
