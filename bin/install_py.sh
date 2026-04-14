#!/usr/bin/env bash
set -e

. ./utils.sh

info "Installing pyenv..."

if curl https://pyenv.run | bash; then
    success "pyenv installed"
else
    error "pyenv installation failed"
    return 1
fi
