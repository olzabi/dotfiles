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
# Any completion that names a path: dirs as a tree, files through bat (darkvoid). Specific styles below win.
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -d $realpath ]] && eza --tree --level=2 --icons --color=always $realpath || { [[ -f $realpath ]] && bat --color=always --style=numbers --line-range=:200 $realpath; }'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff -- $word | delta --width=variable'
zstyle ':fzf-tab:complete:git-(checkout|switch|merge|rebase|log):*' fzf-preview 'git log --oneline --graph --color=always -20 $word 2>/dev/null'
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word 2>/dev/null || SYSTEMD_COLORS=1 systemctl --user status $word'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word 2>/dev/null | col -bx | bat -l man -p --color=always'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-preview 'ps --pid=$word -o cmd --no-header -w -w'
zstyle ':fzf-tab:complete:kill:argument-rest' fzf-flags '--preview-window=down:3:wrap'
zstyle ':fzf-tab:complete:export:argument-1' fzf-preview 'printenv $word'
