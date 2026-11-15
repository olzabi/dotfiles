# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004
# 99-final.zsh -- MUST stay last: these wrap ZLE widgets, so everything that
# binds keys or adds widgets has to load before them.
# Installed from pacman: zsh-autosuggestions zsh-syntax-highlighting

for _f in /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
          /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -r $_f ]] && . "$_f"
done
unset _f
