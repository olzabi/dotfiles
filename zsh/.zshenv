#!/usr/bin/env zsh
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_LOCAL_HOME="$HOME/.local"
export XDG_BIN_HOME="$XDG_LOCAL_HOME/bin"
export XDG_DATA_HOME="$XDG_LOCAL_HOME/share"

export DOTFILES_PATH="$XDG_CONFIG_HOME/dotfiles"
export DEV="$HOME/dev"

# ---------
export LANG="en_US.UTF-8"
export LC_ALL="${LANG}"
export LC_CTYPE="${LANG}"

#* nvim
# ---------
# export PATH="/usr/local/bin:$PATH"
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

#* SSH
# ---------
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# ---------
[[ $- != *i* ]] && return
set -o vi
export MANPAGER='nvim +Man!'
export MANPATH="/usr/local/man:$MANPATH"

# ---------
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig
export PATH="$XDG_LOCAL_HOME/bin:$PATH"

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
export PATH="$ZSH_CUSTOM/plugins/git-fuzzy/bin:$PATH"

# ---------
export YAZI_CONFIG_HOME="$DOTFILES_PATH/yazi"

#* tmux
# ---------
export TMUX_CONF_DIR="$DOTFILES_PATH"

#* eza
# ---------
export PATH="$DOTFILES_PATH/eza/completions/zsh:$PATH"
export EZA_CONFIG_DIR="$DOTFILES_PATH/eza"

#* C++
# ---------
export CC="${commands[gcc]:-$CC}"
export CC="${commands[clang]:-$CC}"
export CXX="${commands[g++]:-$CXX}"
export CXX="${commands[clang++]:-$CXX}"
export CMAKE_CONFIG_DIR="$XDG_CONFIG_HOME/.cmake"

#* docker & k8
export DOCKER_CONFIG="$XDG_CONFIG_HOME/.docker"
export DOCKER_HOST=unix:///var/run/docker.sock
export MINIKUBE_HOME="$XDG_CONFIG_HOME/.minikube"
export ANSIBLE_HOME="$XDG_CONFIG_HOME/.ansible"

#* golang
# ---------
export GOROOT=/usr/local/go
export GOPATH="$XDG_CONFIG_HOME/go"
export GOBIN="$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"

#* rust
# ---------
export RUSTUP_HOME="$XDG_CONFIG_HOME/.rustup"
export CARGO_HOME="$XDG_CONFIG_HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
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
  export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null; then
  export PIPENV_PYTHON="$PYENV_ROOT/shims/python"
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1
fi

#* pnpm
# ---------
export PNPM_HOME="$XDG_DATA_HOME/pnpm"
# export PATH="$PNPM_HOME:$PATH"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

#* nvm
# ---------
export NVM_DIR="$XDG_CONFIG_HOME/.nvm"

#* git
# ---------
export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/.gitconfig"
export LG_CONFIG_FILE="$DOTFILES_PATH/git/lazygit.config.yml" lazygit

# php
# ---------
export PATH="$XDG_CONFIG_HOME/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="$XDG_CONFIG_HOME/herd-lite/bin:$PHP_INI_SCAN_DIR"
export PHPENV_ROOT="$XDG_CONFIG_HOME/.phpenv"
export PATH="$PHPENV_ROOT/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/.composer/vendor/bin:$PATH"

# java
# ---------
export PATH="/usr/lib/jvm/java-11-openjdk-amd64/bin:$PATH"
export PATH="$XDG_LOCAL_HOME/julia-1.8.1/bin:$PATH"

# Perl
# ---------
PATH="$XDG_CONFIG_HOME/perl5/bin${PATH:+:${PATH}}"
export PATH
PERL5LIB="$XDG_CONFIG_HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL5LIB
PERL_LOCAL_LIB_ROOT="$XDG_CONFIG_HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_LOCAL_LIB_ROOT
PERL_MB_OPT="--install_base \"$XDG_CONFIG_HOME/perl5\""
export PERL_MB_OPT
PERL_MM_OPT="INSTALL_BASE=$XDG_CONFIG_HOME/perl5"
export PERL_MM_OPT

# Setup fzf
# ---------
export FZF_BASE=$DOTFILES_PATH/zsh/custom/plugins/fzf
if [[ ! "$PATH" == *$FZF_BASE/bin* ]]; then
  PATH="${PATH:+${PATH}:}$FZF_BASE/bin"
fi

# Yaml
# ---------
export YAMLLINT_CONFIG_FILE="$DOTFILES_PATH/yamllint/.yamllint.yml"

# ---------
export RIPGREP_CONFIG_PATH="$DOTFILES_PATH/.ripgreprc"

# ---------
export EZA_COLORS="di=1;34:ln=36:ex=1;32"
export ZELLIJ_CONFIG_DIR="$DOTFILES_PATH/zellij"

export PATH=/usr/local/cuda/bin:$PATH
