#!/usr/bin/env bash

set -euo pipefail

# ------------------------------------------------------
#  devdocks — tool installer
#  Usage:
#    ./install.sh                  # installs everything
#    ./install.sh all              # installs everything
#
#  Categories:
#    ./install.sh lazy             # lazydocker, lazygit, lazysql
#    ./install.sh languages        # go, rust, pyenv, phpenv, nvm
#    ./install.sh vc               # nvm (version control managers)
#
#  Individual tools:
#    ./install.sh lazydocker
#    ./install.sh lazygit
#    ./install.sh lazysql
#    ./install.sh go
#    ./install.sh rust
#    ./install.sh pyenv
#    ./install.sh phpenv
#    ./install.sh nvm
# ------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"

already_installed() {
  local bin="$1"
  if command -v "$bin" &>/dev/null; then
    warn "$bin is already installed at $(command -v "$bin") — skipping"
    return 0
  fi
  return 1
}

install_lazydocker() {
  info "Installing lazydocker..."
  already_installed lazydocker && return 0

  curl -sSfL \
    https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh |
    bash

  if [[ -f "$HOME/.local/bin/lazydocker" ]]; then
    sudo mv "$HOME/.local/bin/lazydocker" /usr/local/bin/lazydocker
  fi

  command -v lazydocker &>/dev/null ||
    {
      error "lazydocker installation failed"
      return 1
    }
  success "lazydocker installed → run: lazydocker"
}

install_lazygit() {
  info "Installing lazygit..."
  already_installed lazygit && return 0

  local version
  version=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest |
    grep -oE '"tag_name": *"v[^"]+"' |
    cut -d '"' -f4 |
    sed 's/^v//')
  [[ -z "$version" ]] && {
    error "Failed to fetch lazygit version"
    return 1
  }
  info "  Latest version: v$version"

  local tmp_dir
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT

  curl -fsSL \
    "https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_x86_64.tar.gz" \
    -o "$tmp_dir/lazygit.tar.gz"
  tar -xf "$tmp_dir/lazygit.tar.gz" -C "$tmp_dir" lazygit
  sudo cp "$tmp_dir/lazygit" /usr/local/bin/lazygit
  sudo chmod +x /usr/local/bin/lazygit

  command -v lazygit &>/dev/null ||
    {
      error "lazygit installation failed"
      return 1
    }
  success "lazygit installed → run: lazygit"
}

install_lazysql() {
  info "Installing lazysql..."
  already_installed lazysql && return 0

  local version
  version=$(curl -sSf https://api.github.com/repos/jorgerojas26/lazysql/releases/latest |
    grep '"tag_name"' |
    sed 's/.*"tag_name": *"\(.*\)".*/\1/')
  [[ -z "$version" ]] && {
    error "Could not fetch latest lazysql version"
    return 1
  }
  info "  Latest version: $version"

  local arch
  case "$(uname -m)" in
  x86_64) arch="amd64" ;;
  aarch64) arch="arm64" ;;
  *)
    error "Unsupported architecture: $(uname -m)"
    return 1
    ;;
  esac

  local tmp_dir tarball
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT
  tarball="lazysql_Linux_${arch}.tar.gz"

  info "  Downloading $tarball..."
  curl -sSfL \
    "https://github.com/jorgerojas26/lazysql/releases/download/${version}/${tarball}" \
    -o "$tmp_dir/$tarball"
  tar -xzf "$tmp_dir/$tarball" -C "$tmp_dir"
  sudo mv "$tmp_dir/lazysql" /usr/local/bin/lazysql
  sudo chmod +x /usr/local/bin/lazysql

  command -v lazysql &>/dev/null ||
    {
      error "lazysql installation failed"
      return 1
    }
  success "lazysql installed → run: lazysql"
}

install_go() {
  info "Installing Go..."
  already_installed go && return 0

  local version
  version=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n1)
  [[ -z "$version" ]] && {
    error "Failed to fetch Go version"
    return 1
  }
  success "Latest version: $version"

  local archive="$version.linux-amd64.tar.gz"
  info "  Downloading $archive..."
  curl -fsSLO "https://go.dev/dl/${archive}"

  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$archive"
  rm "$archive"
  success "Go installed"
}

install_rust() {
  info "Installing Rust..."
  already_installed rustc && return 0

  if curl https://sh.rustup.rs -sSf | sh -s -- -y; then
    success "Rust installed"
  else
    error "Rust installation failed"
    return 1
  fi
}

install_ruby() {
  info "Installing rbenv + ruby-build..."
  already_installed rbenv && return 0

  if git clone https://github.com/rbenv/rbenv.git ~/.config/.rbenv &&
    git clone https://github.com/rbenv/ruby-build.git ~/.config/.rbenv/plugins/ruby-build; then
    success "rbenv cloned"
  else
    error "rbenv installation failed"
    return 1
  fi

  if [ -z "${RBENV_ROOT:-}" ] && [ -f "$HOME/.zshenv" ]; then
    info "  Sourcing ~/.zshenv..."
    source "$HOME/.zshenv"
  fi

  local version
  version=$(rbenv install -l 2>/dev/null | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
  [[ -z "$version" ]] && {
    error "Failed to fetch latest Ruby version"
    return 1
  }
  info "  Latest stable Ruby: $version"

  rbenv install "$version"
  rbenv global "$version"

  command -v ruby &>/dev/null || {
    error "ruby installation failed"
    return 1
  }
  success "Ruby $version installed → run: ruby --version"
}

install_pyenv() {
  info "Installing pyenv..."
  already_installed pyenv && return 0

  if curl https://pyenv.run | bash; then
    success "pyenv installed"
  else
    error "pyenv installation failed"
    return 1
  fi
}

install_phpenv() {
  info "Installing phpenv..."
  already_installed phpenv && return 0

  if git clone https://github.com/phpenv/phpenv.git ~/.config/.phpenv; then
    success "phpenv cloned"
  else
    error "phpenv installation failed"
    return 1
  fi

  if [ -z "${PHPENV_ROOT:-}" ] && [ -f "$HOME/.zshenv" ]; then
    info "  Sourcing ~/.zshenv..."
    source "$HOME/.zshenv"
  fi

  curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
  success "phpenv installed"
}

install_nvm() {
  info "Installing NVM..."
  already_installed nvm && return 0

  local version
  version=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest |
    grep -oE '"tag_name": *"[^"]+"' |
    cut -d '"' -f4)
  [[ -z "$version" ]] && {
    error "Failed to fetch latest NVM version"
    return 1
  }
  success "Latest version: $version"

  if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${version}/install.sh" | bash; then
    success "NVM installed"
    info "  Reload your shell or run:"
    printf "    %s\n" 'export NVM_DIR="$HOME/.config/.nvm"'
    printf "    %s\n" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
  else
    error "NVM installation failed"
    return 1
  fi
}

install_lazy() {
  install_lazydocker
  install_lazygit
  install_lazysql
}

install_languages() {
  install_go
  install_rust
}

install_vc() {
  install_nvm
  install_pyenv
  install_phpenv
  install_ruby
}

TARGET="${1:-all}"

# shellcheck disable=SC2317  # functions are called via case dispatch below
case "$TARGET" in
lazydocker) install_lazydocker ;;
lazygit) install_lazygit ;;
lazysql) install_lazysql ;;
go) install_go ;;
rust) install_rust ;;
ruby) install_ruby ;;
pyenv) install_pyenv ;;
phpenv) install_phpenv ;;
nvm) install_nvm ;;

lazy)
  info "Installing lazy tools..."
  install_lazy
  echo ""
  success "All lazy tools installed!"
  ;;
languages)
  info "Installing language managers..."
  install_languages
  echo ""
  success "All language managers installed!"
  ;;
vc)
  info "Installing version control managers..."
  install_vc
  echo ""
  success "All vc managers installed!"
  ;;

all)
  info "Installing all tools..."
  echo ""
  install_lazy
  echo ""
  install_languages
  echo ""
  install_vc
  echo ""
  success "All tools installed!"
  ;;
*)
  error "Unknown target: $TARGET"
  echo ""
  echo "  Categories:  lazy | languages | vc | all"
  echo "  Lazy:        lazydocker | lazygit | lazysql"
  echo "  Languages:   go | rust  "
  echo "  VC managers: nvm | ruby | pyenv | phpenv"
  ;;
esac
