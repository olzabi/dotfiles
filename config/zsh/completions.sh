#!/usr/bin/env bash
# Write zsh completions for mise-installed tools into a dir on $fpath.
# pacman used to drop these in /usr/share/zsh/site-functions; mise installs ship none,
# so they are generated from each binary (version-matched) or copied from its tarball.
set -euo pipefail
out=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/site-functions # on fpath via conf.d/30-plugins.zsh
mkdir -p "$out"

gen() { # gen <name> <command...>: skip quietly when the tool is not installed
  local name=$1; shift
  command -v "$1" >/dev/null || return 0
  if "$@" >"$out/_$name.tmp" 2>/dev/null && grep -q compdef "$out/_$name.tmp"; then
    mv "$out/_$name.tmp" "$out/_$name"
  else
    rm -f "$out/_$name.tmp"; echo "skip $name" >&2
  fi
}
gen gh gh completion -s zsh
gen atuin atuin gen-completions --shell zsh
gen rg rg --generate complete-zsh
gen fd fd --gen-completions zsh
gen bat bat --completion zsh
gen delta delta --generate-completion zsh
gen starship starship completions zsh
gen ast-grep ast-grep completions zsh
gen glow glow completion zsh
gen act act completion zsh
gen herdr herdr completion zsh
gen jj jj util completion zsh

# shipped as files in the release tarball
for f in yazi/latest/*/completions/_yazi yazi/latest/*/completions/_ya hyperfine/latest/*/autocomplete/_hyperfine; do
  for p in "$HOME"/.local/share/mise/installs/$f; do [[ -f $p ]] && cp "$p" "$out/"; done
done

rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh/zcompdump* "${ZSH_COMPDUMP:-/nonexistent}" # rebuild on next shell
echo "completions in $out: $(find "$out" -name '_*' | wc -l)"
