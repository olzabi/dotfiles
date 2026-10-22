#typeset -U path PATH

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_LOCAL_HOME="$HOME/.local"
export XDG_BIN_HOME="$HOME/.local/bin"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

export SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-$XDG_RUNTIME_DIR/ssh-agent.socket}

export KB_NAME="Blasphemy Slate"

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8


export DOTFILES="$XDG_CONFIG_HOME/dotfiles"
export DOTFILES_GIT="$DOTFILES/git"
export DOTFILES_EDITOR="$DOTFILES/editor"
export DOTFILES_TOOLS="$DOTFILES/tools"
export DOTFILES_THEMES="$DOTFILES/themes"
export DOTFILES_AI="$DOTFILES/agents"

export DEV="$HOME/dev"
export YAZI_CONFIG_HOME="$DOTFILES_EDITOR/yazi"
export BAT_CONFIG_DIR="$DOTFILES_EDITOR/bat"
export STARSHIP_CONFIG="$DOTFILES/zsh/starship.toml"

_prepend_path() { path=("$1" ${path:#$1}); }
_append_path()  { path=(${path:#$1} "$1"); }

_append_path "/opt/nvim-linux-x86_64/bin"
_prepend_path "$XDG_LOCAL_HOME/bin"

[[ -d /opt/cuda/bin ]] && { _prepend_path /opt/cuda/bin; export CUDA_PATH=/opt/cuda; }

_prepend_path "/usr/lib/jvm/default-java/bin"

export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
export ZSH="$DOTFILES/zsh/ohmyzsh"
export ZSH_CUSTOM="$DOTFILES/zsh/custom"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcomdump-$HOST"
_prepend_path "$ZSH_CUSTOM/plugins/git-fuzzy/bin"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

#* history
# ---------
export HIST_DIR="$XDG_LOCAL_HOME/histfiles"
if [[ ! -d "$HIST_DIR" ]]; then
  mkdir -p "$HIST_DIR"
  touch "$HIST_DIR/.zsh_history" \
    "$HIST_DIR/.psql_history" \
    "$HIST_DIR/.mysql_history" \
    "$HIST_DIR/.python_history" \
    "$HIST_DIR/.psysh_history"
fi
export HISTFILE="$HIST_DIR/.zsh_history"
export PSQL_HISTORY="$HIST_DIR/.psql_history"
export MYSQL_HISTFILE="$HIST_DIR/.mysql_history"
export PYTHON_HISTORY="$HIST_DIR/.python_history"
export PSYSH_CONFIG="$HIST_DIR/psysh_history"

export EZA_CONFIG_DIR="$DOTFILES_TOOLS/eza"
export EZA_COLORS="di=1;34:ln=36:ex=1;32"
_prepend_path "$DOTFILES_TOOLS/eza/completions/zsh"

export RIPGREP_CONFIG_PATH="$DOTFILES/.ripgreprc"
export ZELLIJ_CONFIG_DIR="$DOTFILES_EDITOR/zellij"

#* C++
# ---------
export CC="${commands[gcc]:-$CC}"
export CC="${commands[clang]:-$CC}"
export CXX="${commands[g++]:-$CXX}"
export CXX="${commands[clang++]:-$CXX}"
export CMAKE_CONFIG_DIR="$XDG_CONFIG_HOME/.cmake"

#* docker & k8
# ---------
export DOCKER_CONFIG="$XDG_CONFIG_HOME/.docker"
export MINIKUBE_HOME="$XDG_CONFIG_HOME/.minikube"
export ANSIBLE_HOME="$XDG_CONFIG_HOME/.ansible"

export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

#* golang
# ---------
export GOPATH="$XDG_CONFIG_HOME/go"
export GOBIN="$GOPATH/bin"
_append_path "$GOPATH/bin"

#* rust
# ---------
export RUSTUP_HOME="$XDG_CONFIG_HOME/.rustup"
export CARGO_HOME="$XDG_CONFIG_HOME/.cargo"

_prepend_path "$CARGO_HOME/bin"

# ---------
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
export BUN_INSTALL="$XDG_CONFIG_HOME/.bun"
export NVM_DIR="${NVM_DIR:-$XDG_CONFIG_HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[ -s "${BUN_INSTALL}/_bun" ] && . "${BUN_INSTALL}/_bun"

_prepend_path "$PNPM_HOME"
_prepend_path "$BUN_INSTALL/bin"
_prepend_path "$XDG_CONFIG_HOME/.composer/vendor/bin"

#* git
# ---------
export GH_DASH_CONFIG="$DOTFILES_GIT/gh-dash.config.yml"


export PI_CODING_AGENT_DIR="$DOTFILES_AI/pi/agent"
export CLAUDE_CONFIG_DIR=$DOTFILES_AI/claude
export OPENCODE_CONFIG_DIR=$DOTFILES_AI/opencode

export OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"
export OLLAMA_KEEP_ALIVE=10m

_prepend_path "$OPENCODE_CONFIG_DIR/bin"
_append_path /usr/bin



