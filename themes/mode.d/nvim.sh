#!/usr/bin/env bash
# nvim: running instances get 'background' set; config/nvim/lua/ui/colorscheme.lua then loads darkvoid or the
# light colours (themes/light/nvim.lua, linked as lua/darkvoid_light.lua). New instances detect it from the terminal.
for s in "${XDG_RUNTIME_DIR:-/run/user/$UID}"/nvim.*.0; do
  [[ -S $s ]] && timeout 2 nvim --server "$s" --remote-expr "execute('set background=$1')" >/dev/null 2>&1
done
exit 0
