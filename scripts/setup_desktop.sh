#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/desktop.conf"
source "$CONFIG_DIR/packages/$DISTRO/dwl.conf"

readonly DWL_REPO="https://codeberg.org/dwl/dwl.git"

install_desktop_packages() {
    info "Installing desktop packages"

    install_packages "${DESKTOP_PACKAGES[@]}"

    mkdir -p "$HOME/.config"

    cp -r "$CONFIG_DIR/desktop/foot" "$HOME/.config/"

    success "Desktop packages configured"
}


setup_dwl() {
    info "Setting up dwl"

    create_temp_directory

    install_packages "${DWL_BUILD_PACKAGES[@]}"

    info "Cloning dwl from $DWL_REPO"

    git clone "$DWL_REPO" "$TEMP_DIR/dwl"

    (
        cd "$TEMP_DIR/dwl"
        cp "$CONFIG_DIR/desktop/wm/dwl/config.def.h" .

        vi dwl.c

        make clean
        doas make install
    )

    remove_packages "${DWL_BUILD_PACKAGES[@]}"

    install_packages "${DWL_RUNTIME_PACKAGES[@]}"

    success "dwl installed"
}

setup_desktop() {
    install_desktop_packages
#    setup_dwl
    success "Desktop setup completed"
}
