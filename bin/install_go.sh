#!/usr/bin/env bash
set -e

. ./utils.sh

info "Fetching latest Go version..."

VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -n1)

if [ -z "$VERSION" ]; then
    error "Failed to fetch Go version"
    return 1
fi

success "Latest version: $VERSION"

ARCHIVE="${VERSION}.linux-amd64.tar.gz"
URL="https://go.dev/dl/${ARCHIVE}"

info "Downloading Go..."
curl -fsSLO "$URL"

info "Installing Go..."
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "$ARCHIVE"

rm "$ARCHIVE"

success "Go installed"
