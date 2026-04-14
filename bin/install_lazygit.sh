#!/usr/bin/env bash
set -e

. ./utils.sh

info "Fetching latest lazygit version..."

VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest |
    grep -oE '"tag_name": *"v[^"]+"' |
    cut -d '"' -f4 | sed 's/^v//')

if [ -z "$VERSION" ]; then
    error "Failed to fetch lazygit version"
    return 1
fi

success "Latest version: v$VERSION"

URL="https://github.com/jesseduffield/lazygit/releases/download/v${VERSION}/lazygit_${VERSION}_Linux_x86_64.tar.gz"

info "Downloading lazygit..."
curl -fsSL "$URL" -o lazygit.tar.gz

tar xf lazygit.tar.gz lazygit
sudo cp lazygit /usr/local/bin
rm -f lazygit lazygit.tar.gz

success "lazygit installed"
