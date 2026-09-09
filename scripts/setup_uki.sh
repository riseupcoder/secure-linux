#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/uki.conf"

configure_uki() {
    info "Installing UKI packages"

    install_packages "${UKI_PACKAGES[@]}"

    info "Setting up kernel command line"

    local root_uuid
    root_uuid="$(findmnt -n -o UUID /)"

    sed "s/@ROOT_UUID@/$root_uuid/" \
        "$CONFIG_DIR/system/kernel/cmdline.conf" |
        doas tee /etc/kernel/cmdline >/dev/null

    info "Installing dracut configuration"

    doas install -Dm444 \
        "$CONFIG_DIR/system/dracut/10-hardened.conf" \
        /etc/dracut.conf.d/10-hardened.conf

    info "Installing kernel-install configuration"
    
    doas install -Dm644 \
    "$CONFIG_DIR/system/kernel/install.conf" \
    /etc/kernel/install.conf

    doas ln -sf /dev/null \
    /etc/kernel/install.d/51-dracut-rescue.install

    doas install -Dm755 \
    "$CONFIG_DIR/system/kernel/install.d/93-uki-efiboot.install" \
    /etc/kernel/install.d/93-uki-efiboot.install

    doas install -Dm755 \
    "$CONFIG_DIR/system/kernel/install.d/92-kernel-config.install" \
    /etc/kernel/install.d/92-kernel-config.install
}

install_uki() {
    local kernel_release

    kernel_release="$(uname -r)"

    info "Installing UKI for kernel $kernel_release"

    doas kernel-install add \
        "$kernel_release" \
        "/lib/modules/$kernel_release/vmlinuz"
}


remove_grub() {

  info "Removing grub"

  if [[ "$DISTRO" == "fedora" ]]; then
      doas rm -f /etc/dnf/protected.d/{grub2-,shim}*

      doas dnf remove -y grub2* shim* systemd-boot-unsigned binutils sbsigntools

      doas rm -rf /boot/grub2 /boot/loader /boot/efi/EFI/fedora
  else
      remove_package grub2* shim*
  fi

  info "Cleaning old kernel files"
  doas sh -c 'rm -rf /boot/vmlinuz-* /boot/initramfs-*'
}

setup_uki() {
    remove_grub
    configure_uki
    install_uki

    success "UKI setup completed"
}
