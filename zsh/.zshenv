#!/usr/bin/env zsh
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_LOCAL_HOME="$HOME/.local"
export XDG_BIN_HOME="$XDG_LOCAL_HOME/bin"
export XDG_DATA_HOME="$XDG_LOCAL_HOME/share"

export DOTFILES_PATH="$XDG_CONFIG_HOME/dotfiles"
export DEV="$HOME/dev"

_prepend_path() { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$1:$PATH" ;; esac }
_append_path()  { case ":$PATH:" in *":$1:"*) ;; *) export PATH="$PATH:$1" ;; esac }

# ---------
export LANG="en_US.UTF-8"
export LC_ALL="${LANG}"
export LC_CTYPE="${LANG}"

#* nvim
# ---------
_append_path "/opt/nvim-linux-x86_64/bin"

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# ---------
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
_prepend_path "$XDG_LOCAL_HOME/bin"

#* history
# ---------
export HIST_DIR="$XDG_DATA_HOME/histfiles"
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

#* zsh
# ---------
export ZSH="$DOTFILES_PATH/zsh/.oh-my-zsh"
export ZSH_CUSTOM="$DOTFILES_PATH/zsh/custom"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcomdump-$HOST"
_prepend_path "$ZSH_CUSTOM/plugins/git-fuzzy/bin"

# ---------
export YAZI_CONFIG_HOME="$DOTFILES_PATH/yazi"
export TMUX_CONF_DIR="$XDG_CONFIG_HOME/tmux"

export EZA_CONFIG_DIR="$DOTFILES_PATH/eza"
export EZA_COLORS="di=1;34:ln=36:ex=1;32"
_prepend_path "$DOTFILES_PATH/eza/completions/zsh"

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
# RUST_SRC_PATH goes in .zshrc — spawning rustc on every shell is too slow:
# export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
[ -f "$CARGO_HOME/env" ] && source "$CARGO_HOME/env"

#* aws
# ---------
export AWS_HOME="$DOTFILES_PATH/aws"
export AWS_CONFIG_FILE="$AWS_HOME/config"
export AWS_SHARED_CREDENTIALS_FILE="$AWS_HOME/credentials"

#* python
# ---------
export PYENV_ROOT="${PYENV_ROOT:-${XDG_CONFIG_HOME:-$HOME/.config}/.pyenv}"
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

#* git
# ---------
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"
export LG_CONFIG_FILE="$DOTFILES_PATH/git/lazygit.config.yml"

# php
# ---------
export PHPENV_ROOT="$XDG_CONFIG_HOME/.phpenv"
_prepend_path "$PHPENV_ROOT/bin"
_prepend_path "$XDG_CONFIG_HOME/.composer/vendor/bin"

# java
# ---------
_prepend_path "/usr/lib/jvm/java-11-openjdk-amd64/bin"
_prepend_path "$XDG_LOCAL_HOME/julia-1.8.1/bin"

# Perl
# ---------
_prepend_path "$XDG_CONFIG_HOME/perl5/bin"
export PERL5LIB="$XDG_CONFIG_HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$XDG_CONFIG_HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$XDG_CONFIG_HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$XDG_CONFIG_HOME/perl5"

# fzf
# ---------
export FZF_BASE="$DOTFILES_PATH/zsh/custom/plugins/fzf"
_append_path "$FZF_BASE/bin"
export RIPGREP_CONFIG_PATH="$DOTFILES_PATH/.ripgreprc"

# Yaml
# ---------
export YAMLLINT_CONFIG_FILE="$DOTFILES_PATH/yamllint/.yamllint.yml"

# ---------
export ZELLIJ_CONFIG_DIR="$DOTFILES_PATH/zellij"

export RBENV_ROOT="$XDG_CONFIG_HOME/.rbenv"
_prepend_path "$RBENV_ROOT/bin"

_prepend_path "/usr/local/cuda/bin"

