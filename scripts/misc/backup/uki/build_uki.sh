#!/bin/bash
set -euo pipefail

doas dnf install -y sbsigntools efitools openssl binutils systemd-boot

BUILT_VERSION="7.0.9-205.fc44.x86_64" # replace this with latest version installed
VMLINUZ="/boot/efi/b08dfa6083e7567a1921a715000001fb/$BUILT_VERSION/linux" 
INITRAMFS="/boot/efi/b08dfa6083e7567a1921a715000001fb/$BUILT_VERSION/initrd"

doas dracut \
  --force \
  --uefi \
  --kver "$BUILT_VERSION" \
  --kernel-image "$VMLINUZ" \
  --kernel-cmdline "@/etc/kernel/cmdline.d/cmdline.conf" \
  "/boot/efi/EFI/BOOT/BOOTX64-$BUILT_VERSION.EFI"

UKI_PATH="/boot/efi/EFI/BOOT/BOOTX64-$BUILT_VERSION.EFI"

doas sbsign \
  --key /etc/efikeys/db.key \
  --cert /etc/efikeys/db.crt \
  --output "$UKI_PATH" \
  "$UKI_PATH"

doas efibootmgr \
  --create \
  --disk /dev/nvme0n1 \
  --part 1 \
  --loader "\\EFI\\BOOT\\BOOTX64-$BUILT_VERSION.EFI" \
  --label "Distro Kernel $BUILT_VERSION" \
  --verbose

doas dnf remove -y sbsigntools systemd-boot-unsigned openssh* less efitools parted elfutils-debuginfod-client openssl

echo "UKI created successfully."
