# ---------
FZF_DEFAULT_COMMAND='rg --follow --no-ignore-vcs --hidden -g "!{node_modules/*,.git/*,target/*,bzl-build/*,}"'
FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --bind 'ctrl-p:change-preview-window(down|hidden|)'"

FZF_DEFAULT_OPTS=""
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
--color=fg:#ebdbb2,fg+:#d5c4a1,bg:#282828,bg+:#3c3836
--color=hl:#fabd2f,hl+:#d79921,info:#665c54,marker:#83a598
--color=prompt:#665c54,spinner:#665c54,pointer:#83a598,header:#665c54
--color=border:#3c3836,label:#665c54,query:#ebdbb2
--border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
--marker=">" --pointer="▌" --separator="─" --scrollbar="│"
--layout="reverse" --border top'

