#!/usr/bin/env bash

set -euo pipefail

debloat_fedora() {
    info "Removing unnecessary Fedora packages"

   local REMOVE_PACKAGES=("atheros*" "brcmfmac*" "cirrus-audio*" "intel*" "nvidia*" "mt7xxx*" "nxpwireless*" "qcom-wwan-firmware" "tiwilink-firmware" "liberation*" "google-noto-sans-mono-vf-fonts" "geolite*" "hunspell*" "exfat*" "qrencode*" "memstrack" "ntfs*" "nano" "pinentry" "man-db" "nvme-cli" "passim" "wcurl" "tpm2-tools" "btrfs-progs" "xfsprogs" "sssd*" "kpartx" "parted" "udisks2" "udftools" "elfutils-debuginfod*" "flashrom" "plymouth*" "mtools" "less" "openssh*" "avahi-daemon*" "systemd-resolved" "bluez" "libqmi" "elfutils-debuginfod-client")

    remove_packages "${REMOVE_PACKAGES[@]}"

    doas dnf autoremove -y

    doas systemctl mask dnf-makecache.timer
    doas systemctl mask dnf-makecache.service
    doas systemctl mask NetworkManager-wait-online.service

    doas systemctl restart NetworkManager
    sleep 5

    success "Fedora debloat complete"
}

