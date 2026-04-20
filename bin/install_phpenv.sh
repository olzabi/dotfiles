#!/usr/bin/env bash
set -e

. ./utils.sh

info "Installing phpenv..."

if git clone https://github.com/phpenv/phpenv.git ~/.config/.phpenv; then
  success "phpenv installed"
else
  error "phpenv installation failed"
  return 1
fi

if [ -z "${PHPENV_ROOT:-}" ] && [ -f "$HOME/.zshenv" ]; then
    info "Sourcing ~/.zshenv..."
    source "$HOME/.zshenv"
fi

curl -L https://raw.githubusercontent.com/phpenv/phpenv-installer/master/bin/phpenv-installer | bash
