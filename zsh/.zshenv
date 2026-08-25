#!/usr/bin/env zsh
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_LOCAL_HOME="$HOME/.local"
export XDG_BIN_HOME="$XDG_LOCAL_HOME/bin"
export XDG_DATA_HOME="$XDG_LOCAL_HOME/share"
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}

export DOTFILES="$XDG_CONFIG_HOME/dotfiles"
export DOTFILES_GIT="$DOTFILES/git"
export DOTFILES_EDITOR="$DOTFILES/editor"
export DOTFILES_TOOLS="$DOTFILES/tools"
export DOTFILES_THEMES="$DOTFILES/themes"
export DOTFILES_AI="$DOTFILES/agents"

export DEV="$HOME/dev"
export YAZI_CONFIG_HOME="$DOTFILES/yazi"
export BAT_CONFIG_DIR="$DOTFILES_TOOLS/bat"
export STARSHIP_CONFIG="$DOTFILES/zsh/starship.toml"

_prepend_path() { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH" ;; esac }
_append_path()  { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$PATH:$1" ;; esac }

_append_path "/opt/nvim-linux-x86_64/bin"
_prepend_path "$XDG_LOCAL_HOME/bin"
_prepend_path "/usr/local/cuda/bin"
_prepend_path "/usr/lib/jvm/default-java/bin"
_prepend_path "$DOTFILES_TOOLS/.fzf/bin"

export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
export ZSH="$DOTFILES/zsh/.oh-my-zsh"
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
export DOCKER_HOST=unix:///var/run/docker.sock
export MINIKUBE_HOME="$XDG_CONFIG_HOME/.minikube"
export ANSIBLE_HOME="$XDG_CONFIG_HOME/.ansible"

#* golang
# ---------
export GOROOT=/usr/local/go
export GOPATH="$XDG_CONFIG_HOME/go"
export GOBIN="$GOPATH/bin"
_append_path "$GOROOT/bin"
_append_path "$GOPATH/bin"

#* rust
# ---------
export RUSTUP_HOME="$XDG_CONFIG_HOME/.rustup"
export CARGO_HOME="$XDG_CONFIG_HOME/.cargo"
_prepend_path "$CARGO_HOME/bin"
[ -f "$CARGO_HOME/env" ] && source "$CARGO_HOME/env"

#* python
# ---------
export PYENV_ROOT="$DOTFILES_TOOLS/.pyenv"
if [ -d "$PYENV_ROOT/bin" ]; then
  _prepend_path "$PYENV_ROOT/bin"
fi

if command -v pyenv >/dev/null; then
  export PIPENV_PYTHON="$PYENV_ROOT/shims/python"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi

#* pnpm
# ---------
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
_prepend_path "$PNPM_HOME"

# ---------
export BUN_INSTALL="$XDG_CONFIG_HOME/.bun"
_prepend_path "$BUN_INSTALL/bin"

#* git
# ---------
export GH_DASH_CONFIG="$DOTFILES_GIT/gh-dash.config.yml"

# php
# ---------
export PHPENV_ROOT="$DOTFILES_TOOLS/.phpenv"
_prepend_path "$PHPENV_ROOT/bin"
_prepend_path "$XDG_CONFIG_HOME/.composer/vendor/bin"


# Perl
# ---------
_prepend_path "$XDG_CONFIG_HOME/perl5/bin"
export PERL5LIB="$XDG_CONFIG_HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$XDG_CONFIG_HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$XDG_CONFIG_HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$XDG_CONFIG_HOME/perl5"

export RIPGREP_CONFIG_PATH="$DOTFILES/.ripgreprc"

export YAMLLINT_CONFIG_FILE="$DOTFILES_TOOLS/yamllint/.yamllint.yml"
export ZELLIJ_CONFIG_DIR="$DOTFILES_EDITOR/zellij"
export RBENV_ROOT="$DOTFILES_TOOLS/.rbenv"
_prepend_path "$RBENV_ROOT/bin"

# ---------

# export AWS_HOME="$DOTFILES/aws"
# export AWS_CONFIG_FILE="$AWS_HOME/config"
# export AWS_SHARED_CREDENTIALS_FILE="$AWS_HOME/credentials"
