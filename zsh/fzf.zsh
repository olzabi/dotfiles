export FZF_DEFAULT_COMMAND='rg --follow --hidden \
  --glob "!{.git,node_modules,target,bzl-build,.svn}/**" \
  --glob "!*.{lock,svg,ttf}" \
  --glob "!package-lock.json"'

export FZF_DEFAULT_OPTS="
  --color=bg:#1c1c1c,bg+:#303030,gutter:#1c1c1c
  --color=fg:#c0c0c0,fg+:#f1f1f1
  --color=hl:#1bfd9c,hl+:#bdfe58
  --color=info:#585858,border:#404040,separator:#404040
  --color=prompt:#1bfd9c,pointer:#bdfe58,marker:#bdfe58
  --color=spinner:#1bfd9c,header:#585858,label:#585858
  --color=query:#d1d1d1,scrollbar:#404040
  --border=rounded
  --prompt='❯ ' --pointer='▌' --marker='●'
  --separator='╌' --scrollbar='▐'
  --layout=reverse --height=60%
  --info=right
  --preview-window=right:55%:border-left:wrap
  --preview='bat --color=always --style=numbers,changes --line-range :200 {}'
  --bind='ctrl-p:toggle-preview'
  --bind='ctrl-/:change-preview-window(right:70%|right:30%|hidden)'
  --bind='ctrl-y:execute-silent(echo {} | wl-copy)'
  --bind='ctrl-e:execute(nvim {} < /dev/tty)'
  --bind='alt-a:select-all'
  --bind='alt-d:deselect-all'
"

# file picker
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
  --header='  ctrl-e: open in nvim  ctrl-y: copy path'
"

# history
export FZF_CTRL_R_OPTS="
  --preview='echo {}'
  --preview-window=down:3:wrap
  --bind='ctrl-p:toggle-preview'
  --sort --exact
  --header='  ctrl-r: toggle sort'
"

# cd picker
export FZF_ALT_C_COMMAND='fd --type=d --hidden --follow \
  --exclude ".git" --exclude "node_modules" --exclude "target"'
export FZF_ALT_C_OPTS="
  --preview='eza --tree --level=2 --color=always {}'
"

rg-fzf() {
  local RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case"
  local INITIAL_QUERY="${*:-}"

  fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --bind "start:reload:$RG_PREFIX {q}" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(fzf ❯ )+enable-search+clear-query" \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --prompt 'rg ❯ ' \
    --delimiter : \
    --preview 'bat --color=always {1} --highlight-line {2} --style=numbers,changes' \
    --preview-window 'right:55%:border-left:+{2}+3/3:wrap' \
    --header 'ctrl-f: switch to fzf mode' \
    | awk -F: '{print $1" +"$2}' \
    | xargs -r nvim
}

bindkey -s '^G' 'rg-fzf\n'


