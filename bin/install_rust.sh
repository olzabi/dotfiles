#!/usr/bin/env bash
set -e

. ./utils.sh

install_rust() {
    info "Installing Rust..."

    if curl https://sh.rustup.rs -sSf | sh -s -- -y; then
        success "Rust installed"
    else
        error "Rust installation failed"
        return 1
    fi
}
