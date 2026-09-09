#!/usr/bin/env bash

set -euo pipefail

source "$PWD/lib/common.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/package_manager.sh"
source "$LIB_DIR/distro.sh"

source "$CONFIG_DIR/packages/$DISTRO/uki.conf"

setup_uki() {
    info "Installing UKI packages"

    install_packages "${UKI_PACKAGES[@]}"

    info "Setting up kernel parameters"

    local root_uuid

    root_uuid="$(findmnt -n -o UUID /)"
   
    doas mkdir -p "/etc/kernel/cmdline.d"

    sed "s/@ROOT_UUID@/$root_uuid/" \
        "$CONFIG_DIR/system/kernel/cmdline.conf" |
        doas tee /etc/kernel/cmdline.d/cmdline.conf >/dev/null

    doas install -m 444 \
        "$CONFIG_DIR/system/dracut/10-hardened.conf" \
        /etc/dracut.conf.d/10-hardened.conf

    success "UKI configuration completed"
}

build_uki() {
    local built_version
    local uki_path

    built_version="$(uname -r)"
    uki_path="/boot/efi/EFI/BOOT/BOOTX64-$built_version.EFI"

    info "Building minimal initramfs"

    doas dracut \
        --force \
        --uefi \
        --kver "$built_version" \
        --kernel-cmdline "@/etc/kernel/cmdline.d/cmdline.conf" \
        "$uki_path"

    doas mkdir -p /etc/efikeys

    info "Generating UKI signing key"

    doas openssl req -newkey rsa:4096 \
        -x509 \
        -sha512 \
        -days 1095 \
        -keyout /etc/efikeys/db.key \
        -out /etc/efikeys/db.crt \
        -subj "/CN=Secure UKI Key"

    info "Signing UKI"

    doas sbsign \
        --key /etc/efikeys/db.key \
        --cert /etc/efikeys/db.crt \
        --output "$uki_path" \
        "$uki_path"

    info "Creating EFI boot entry"

    doas efibootmgr \
        --create \
        --disk /dev/nvme0n1 \
        --part 1 \
        --loader "\\EFI\\BOOT\\BOOTX64-$built_version.EFI" \
        --label "Distro Kernel $built_version" \
        --verbose

    info "Removing grub and shim"

    if [[ "$DISTRO" == "fedora" ]]; then
        doas rm -f /etc/dnf/protected.d/{grub2-,shim}*

        doas dnf remove -y \
            grub2* \
            shim* \
            systemd-boot-unsigned \
            binutils \
            sbsigntools

        doas rm -rf \
            /boot/grub2 \
            /boot/loader \
            /boot/efi/EFI/fedora
    fi

    info "Creating EFI directories"

    local machine_id

    machine_id="$(cat /etc/machine-id)"

    doas mkdir -p \
        "/boot/efi/$machine_id" \
        /boot/efi/loader/entries

    info "Cleaning old kernel files"

    doas sh -c 'rm -rf /boot/vmlinuz-* /boot/initramfs-*'

    success "UKI EFI boot setup completed"
}

main() {
    detect_distribution
    detect_package_manager

    setup_uki
    build_uki
}

main
