for _f in aliases functions fzf; do
  [[ -r $ZSHCONF/$_f.zsh ]] && . "$ZSHCONF/$_f.zsh"
done
unset _f
