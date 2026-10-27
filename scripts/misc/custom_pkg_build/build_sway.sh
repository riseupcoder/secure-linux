#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/desktop/sway.conf"

export CFLAGS="-march=native"
export CXXFLAGS="-march=native"

readonly SWAY_REPO="https://github.com/swaywm/sway.git"
readonly SWAY_VERSION="1.12"

build_sway() {
    info "Setting up Sway"

    create_temp_directory

    install_packages "${SWAY_BUILD_PACKAGES[@]}" git

    info "Cloning Sway from $SWAY_REPO"

    git clone "$SWAY_REPO" "$TEMP_DIR/sway"

    (
        cd "$TEMP_DIR/sway"

        git fetch --tags
        git checkout --detach "$SWAY_VERSION"

        info "Building Sway $SWAY_VERSION"

        meson setup build/ \
            --prefix=/usr/local \
            --buildtype=release \
            -Ddefault-wallpaper=false \
            -Dzsh-completions=false \
            -Dbash-completions=false \
            -Dfish-completions=false \
            -Dswaybar=false \
            -Dswaynag=false \
            -Dtray=disabled \
            -Dgdk-pixbuf=disabled \
            -Dman-pages=disabled \
            -Dsd-bus-provider=auto

        ninja -C build/

        doas ninja -C build/ install

        doas ldconfig
    )

    remove_packages "${SWAY_BUILD_PACKAGES[@]}"

    install_packages "${SWAY_RUNTIME_PACKAGES[@]}"

    success "Sway installed"
}
