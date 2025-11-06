#!/usr/bin/env zsh

#* nvim
# ---------
# export PATH="/usr/local/bin:$PATH"

# ---------
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# ---------
export LANG="en_US.UTF-8"
export LC_ALL="${LANG}"
export LC_CTYPE="${LANG}"

# ---------
[[ $- != *i* ]] && return
set -o vi
export MANPAGER='nvim +Man!'
export MANPATH="/usr/local/man:$MANPATH"

# ---------
export PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

# ---------
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_LOCAL_HOME="$HOME/.local"
export XDG_BIN_HOME="$XDG_LOCAL_HOME/bin"
export XDG_DATA_HOME="$XDG_LOCAL_HOME/share"

export DOTFILES_PATH="$XDG_CONFIG_HOME/dotfiles"
export NOTES_PATH="$HOME/vaults/notes"
export DEV="$HOME/dev"
export WORK="$DEV/work"

#* history
export HISTFILE="$XDG_DATA_HOME/bash/.bash_history"
export PSQL_HISTORY="$XDG_DATA_HOME/psql/.psql_history"
export MYSQL_HISTFILE="$XDG_DATA_HOME/mysql/.mysql_history"
export PYTHON_HISTORY="$XDG_DATA_HOME/python/history"

#* for local binaries (e.g. cmd tools)
# ---------
export PATH="$XDG_LOCAL_HOME/bin:$PATH"
export PATH="$HOME/bin:/usr/local/bin:$PATH"

#* zsh
# ---------
export ZSH="$DOTFILES_PATH/zsh/.oh-my-zsh"
export ZSH_CUSTOM="$DOTFILES_PATH/zsh/custom"
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/.zcomdump-$HOST"
export PATH="$ZSH_CUSTOM/plugins/git-fuzzy/bin:$PATH"

# ---------
export ANSIBLE_HOME="$XDG_CONFIG_HOME/.ansible"
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

#* docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME/.docker"

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
export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
export PATH="$CARGO_HOME/bin:$PATH"
[ -f "$CARGO_HOME/env" ] && source "$CARGO_HOME/env"

#* aws
# ---------
export AWS_HOME="$DOTFILES_PATH/aws"
export AWS_CONFIG_FILE="$AWS_HOME/config"
export AWS_SHARED_CREDENTIALS_FILE="$AWS_HOME/credentials"

#* python
# ---------
export PYENV_ROOT="$XDG_CONFIG_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

#* npm
# ---------
# export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
# export NPM_CONFIG_DEVDIR="$XDG_CACHE_HOME/node-gyp"

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
export GIT_CONFIG_GLOBAL="$DOTFILES_PATH/git/.gitconfig"

#* lazygit
# ---------
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

# julia
# ---------
export PATH="$HOME/.local/julia-1.8.1/bin:$PATH"

# Perl
# ---------
PATH="$XDG_CONFIG_HOME/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="$XDG_CONFIG_HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="$XDG_CONFIG_HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"$XDG_CONFIG_HOME/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=$XDG_CONFIG_HOME/perl5"; export PERL_MM_OPT;

#* nix
# ---------
# export NIX_HOME="$XDG_CONFIG_HOME/nix"
# export NIX_USER_PROFILE_DIR="$NIX_HOME/profile"
# export NIX_PATH="nixpkgs=$NIX_HOME/defexpr/channels/nixpkgs:$NIX_HOME/defexpr/channels"
# export NIX_PROFILES="$NIX_PATH/.nix-profile $NIX_USER_PROFILE_DIR"
# export PATH="$NIX_USER_PROFILE_DIR/bin:$PATH"

# Setup fzf
# ---------
export FZF_BASE=$DOTFILES_PATH/zsh/custom/plugins/fzf
if [[ ! "$PATH" == *$FZF_BASE/bin* ]]; then
  PATH="${PATH:+${PATH}:}$FZF_BASE/bin"
fi

export FZF_CTRL_T_OPTS="
  --preview 'bat -n --color=always {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'"
export FZF_DEFAULT_COMMAND='rg --hidden -l ""' # Include hidden files


export FZF_DEFAULT_OPTS=" \
  --tmux bottom,20% --height 20% --style minimal \
  --layout=reverse --border top \
  --bind=ctrl-space:accept"

# ---------
export EZA_COLORS="di=1;34:ln=36:ex=1;32"

export GIT_EMAIL="olzabi14@gmail.com"
export GIT_NAME="olzabi"
