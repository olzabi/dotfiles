#!/usr/bin/env zsh
# shellcheck shell=bash disable=SC2034,SC2154,SC2016,SC1091,SC2004

if [[ -n $_ZSHRC_LOADED && -o interactive ]]; then
  [[ -o login ]] && exec zsh -l || exec zsh
fi
_ZSHRC_LOADED=1

# %x = this file as sourced (the ~/.zshrc symlink); :A resolves it to the real
# path, so ZSHCONF is the dotfiles/zsh directory wherever the repo is cloned.
ZSHCONF=${${(%):-%x}:A:h}

for _f in "$ZSHCONF"/conf.d/*.zsh(N); do
  source "$_f"
done
unset _f

# >>> headroom persistent env >>>
export HEADROOM_PORT="8787"
export HEADROOM_HOST="127.0.0.1"
export HEADROOM_MODE="cache"
export HEADROOM_BACKEND="anthropic"
export HEADROOM_EMBEDDER_RUNTIME="cpu"
export HEADROOM_KOMPRESS_BACKEND="onnx"
export HEADROOM_TELEMETRY="off"
export ANTHROPIC_BASE_URL="http://127.0.0.1:8787"
export ENABLE_TOOL_SEARCH="true"
# <<< headroom persistent env <<<
