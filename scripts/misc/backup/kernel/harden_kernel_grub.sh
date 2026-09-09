#!/bin/bash
set -e

KERNEL_VERSION=""
KERNEL_NAME="${KERNEL_VERSION}-hardened1"
HARDENED_PATCH_VERSION="v${KERNEL_VERSION}-hardened1"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"
PATCH_URL="https://github.com/anthraxx/linux-hardened/releases/download/${HARDENED_PATCH_VERSION}/linux-hardened-${HARDENED_PATCH_VERSION}.patch"
PATCH_SIG_URL="https://github.com/anthraxx/linux-hardened/releases/download/${HARDENED_PATCH_VERSION}/linux-hardened-${HARDENED_PATCH_VERSION}.patch.sig"

# Install dependencies
doas dnf install -y gcc make binutils flex bison ncurses-devel elfutils-libelf-devel openssl-devel dwarves gzip xz patch bc git gnupg2 openssl

# Download and verify kernel
echo "Downloading kernel..."
if [ -f "linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "Kernel archive already exists. Skipping download."
else
    curl --proto '=https' --tlsv1.2 --tls-max 1.3 -sLf "$KERNEL_URL" -O
    curl --proto '=https' --tlsv1.2 -sSL "https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc" -o sha256sums.asc
fi

awk -v file="linux-${KERNEL_VERSION}.tar.xz" '$0 ~ file {print $0; exit}' sha256sums.asc | sha256sum -c --ignore-missing - || { echo "Kernel hash mismatch!"; exit 1; }

# Extract
tar -xf "linux-${KERNEL_VERSION}.tar.xz"
cd "linux-${KERNEL_VERSION}"

# Download and verify hardened patch
echo "Downloading and verifying linux-hardened patch..."
if [ -f "../patch" ] && [ -f "../patch.sig" ]; then
    echo "Patch and signature already exist. Skipping download."
else
    curl --proto '=https' --tlsv1.2 --tls-max 1.3 -fsSL "$PATCH_URL" -o "../patch"
    curl --proto '=https' --tlsv1.2 --tls-max 1.3 -fsSL "$PATCH_SIG_URL" -o "../patch.sig"
fi
gpg --auto-key-locate wkd --locate-keys anthraxx@archlinux.org
gpg --verify "../patch.sig" "../patch" || { echo "Patch signature verification failed!"; exit 1; }

# Apply patch
if patch -p1 -N --dry-run < "../patch"; then
    patch -p1 -N < "../patch"
else
    echo "Patch already applied or failed."
fi

# Restore and update config
doas cp /boot/config-$(uname -r) .config

doas make olddefconfig
# doas make LSMOD="$HOME/lsmod.txt" localmodconfig
doas make localmodconfig

# Optional: let user customize
doas make menuconfig

# Build
doas make -j$(nproc) 

# Install
doas make modules_install

doas make install

echo "Generating initramfs..."
BUILT_VERSION="$(doas make -s kernelrelease)"
doas dracut --force "/boot/initramfs-$BUILT_VERSION.img" "$BUILT_VERSION"

echo "Updating GRUB..."
doas grub2-mkconfig -o /boot/grub2/grub.cfg

doas cp .config /boot/config-${KERNEL_NAME}

doas dnf remove gcc make binutils flex bison ncurses-devel elfutils-libelf-devel openssl-devel dwarves patch bc git openssl

echo "Hardened kernel installed. Reboot to use."
