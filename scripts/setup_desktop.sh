#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/desktop/desktop.conf"

install_desktop_packages() {
    info "Installing desktop packages"

    install_packages "${DESKTOP_PACKAGES[@]}"

    mkdir -p "$HOME/.config"

    cp -r "$CONFIG_DIR/desktop/foot" "$HOME/.config/"

    success "Desktop packages configured"
}

setup_desktop() {
    install_desktop_packages
    success "Desktop setup completed"
}
