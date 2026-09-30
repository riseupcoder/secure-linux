#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/dwl.conf"
readonly DWL_REPO="https://codeberg.org/dwl/dwl.git"

build_dwl() {
    info "Setting up dwl"

    create_temp_directory

    install_packages "${DWL_BUILD_PACKAGES[@]}" git

    info "Cloning dwl from $DWL_REPO"

    git clone "$DWL_REPO" "$TEMP_DIR/dwl"

    (
        cd "$TEMP_DIR/dwl"
        git fetch --tags
        git checkout v0.9

        cp "$CONFIG_DIR/desktop/wm/dwl/config.def.h" .

        vi dwl.c

        make clean
        doas make install
    )

    remove_packages "${DWL_BUILD_PACKAGES[@]}"

    install_packages "${DWL_RUNTIME_PACKAGES[@]}"
    
    doas usermod -aG seat $USER
    doas systemctl enable seatd.service

    success "dwl installed"
}
