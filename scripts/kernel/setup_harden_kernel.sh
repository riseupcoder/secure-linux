#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/kernel.conf"
source "$CONFIG_DIR/system/kernel/kernel.conf"
source "$CONFIG_DIR/system/kernel/modules.conf"

KERNEL_RELEASE=""

download_kernel() {
    local KERNEL_ARCHIVE="linux-${KERNEL_VERSION}.tar.xz"

    if [[ ! -f "$KERNEL_ARCHIVE" ]]; then
        info "Downloading kernel source"

        curl -fsSL "$KERNEL_URL" -O
    fi

    if [[ ! -f "sha256sums.asc" ]]; then
        info "Downloading kernel checksums"

        curl -fsSL "$KERNEL_SHASUM_URL" -o sha256sums.asc
    fi

    info "Verifying kernel source"

    awk -v file="$KERNEL_ARCHIVE" \
        '$0 ~ file {print $0; exit}' \
        sha256sums.asc |
        sha256sum -c -

    if [[ -d "linux-${KERNEL_VERSION}" ]]; then
        info "Kernel source already extracted"
        return
    fi

    info "Extracting kernel source"

    tar -xf "$KERNEL_ARCHIVE"
}


apply_kernel_patch() {
    local PATCH="../patch"
    local PATCH_SIG="../patch.sig"

    if [[ ! -f "$PATCH" ]]; then
        info "Downloading hardened kernel patch"

        curl -fsSL "$PATCH_URL" -o "$PATCH"
    fi

    if [[ ! -f "$PATCH_SIG" ]]; then
        info "Downloading hardened kernel patch signature"

        curl -fsSL "$PATCH_SIG_URL" -o "$PATCH_SIG"
    fi

    info "Importing linux-hardened signing key"

    gpg \
        --auto-key-locate wkd \
        --locate-keys \
        anthraxx@archlinux.org

    info "Verifying hardened kernel patch signature"

    gpg --verify \
        "$PATCH_SIG" \
        "$PATCH"
    
    info "Checking hardened kernel patch"

    if patch -p1 --dry-run < "../patch" >/dev/null 2>&1; then
        info "Applying hardened kernel patch"
        patch -p1 -N < "../patch"
    elif patch -p1 -R --dry-run < "../patch" >/dev/null 2>&1; then
        info "Hardened kernel patch already applied"
    else
        error "Hardened kernel patch cannot be applied"
        exit 1
    fi
}


configure_kernel() {
    info "Preparing kernel configuration"

    doas cp "/boot/config-$(uname -r)" .config

    doas chown "$USER:$USER" .config

    info "Loading required kernel modules"

    for module in "${KERNEL_MODULES[@]}"; do
        doas modprobe "$module"
    done

    info "Updating kernel configuration"

    make olddefconfig
    make localmodconfig

    info "Opening kernel configuration"

    make menuconfig

    # Kbuild is the source of truth for the final kernel release.
    KERNEL_RELEASE="$(make -s kernelrelease)"

    if [[ -z "$KERNEL_RELEASE" ]]; then
        error "Unable to determine kernel release"
        exit 1
    fi

    info "Kernel release: $KERNEL_RELEASE"
}

build_kernel() {
    info "Building kernel $KERNEL_RELEASE"

    make -j "$(nproc)"

    info "Installing kernel modules"

    doas make modules_install

    info "Installing kernel image"

    doas install -Dm644 \
        ./arch/x86/boot/bzImage \
        "/lib/modules/$KERNEL_RELEASE/vmlinuz"

    info "Installing kernel configuration"

    doas cp .config "/boot/config-$KERNEL_RELEASE"
}

install_kernel() {
    info "Installing UKI through kernel-install"

    doas kernel-install add \
        "$KERNEL_RELEASE" \
        "/lib/modules/$KERNEL_RELEASE/vmlinuz"
}

setup_harden_kernel() {
    create_temp_directory
    trap remove_temp_directory EXIT

    install_packages "${KERNEL_BUILD_PACKAGES[@]}" git

    cd "$TEMP_DIR"

    download_kernel

    cd "linux-${KERNEL_VERSION}"

    apply_kernel_patch
    configure_kernel
    build_kernel
    install_kernel

    cd "$ROOT_DIR"

    remove_packages "${KERNEL_BUILD_PACKAGES[@]}"

    success "Hardened kernel installed: $KERNEL_RELEASE"
}
