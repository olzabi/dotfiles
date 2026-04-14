#!/usr/bin/env bash
set -e

. ./utils.sh

info "Fetching latest NVM version..."

LATEST_NVM_VERSION=$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest |
  grep -oE '"tag_name": *"[^"]+"' |
  cut -d '"' -f4)

if [ -z "$LATEST_NVM_VERSION" ]; then
  error "Failed to fetch latest NVM version"
  exit 1
fi

success "Latest version: $LATEST_NVM_VERSION"

info "Installing NVM..."

if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${LATEST_NVM_VERSION}/install.sh" | bash; then
  success "NVM installed successfully"
else
  error "NVM installation failed"
  exit 1
fi

info "Reload your shell or run:"
printf "%s\n" 'export NVM_DIR="$HOME/.config/.nvm"'
printf "%s\n" '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"'
