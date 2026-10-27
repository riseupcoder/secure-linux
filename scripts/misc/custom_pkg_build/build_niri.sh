#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/desktop/niri.conf"

readonly NIRI_REPO="https://github.com/niri-wm/niri.git"

niri_setup() {
    info "Setting up niri"

    create_temp_directory

    install_packages "${NIRI_BUILD_PACKAGES[@]}" git curl

    info "Installing Rust toolchain"

    if ! command -v cargo >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi

    source "$HOME/.cargo/env"

    info "Cloning niri from $NIRI_REPO"

    git clone "$NIRI_REPO" "$TEMP_DIR/niri"

    (
        cd "$TEMP_DIR/niri"

        cargo build --release --no-default-features

        info "Installing niri binaries"

        doas install -Dm755 target/release/niri /usr/local/bin/niri
        doas install -Dm755 resources/niri-session /usr/local/bin/niri-session

        doas install -Dm644 resources/niri.desktop \
            /usr/local/share/wayland-sessions/niri.desktop
    )

    remove_packages "${NIRI_BUILD_PACKAGES[@]}"

    install_packages "${NIRI_RUNTIME_PACKAGES[@]}"

    success "niri installed"
}

remove_niri() {
    info "Removing niri runtime packages"

    remove_packages "${NIRI_RUNTIME_PACKAGES[@]}"
}

