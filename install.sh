#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$ROOT_DIR/lib"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/filesystem.sh"
source "$LIB_DIR/distro.sh"
source "$LIB_DIR/package_manager.sh"
source "$LIB_DIR/selinux.sh"

readonly SETUP_SCRIPTS=(
    "scripts/setup_doas.sh:setup_doas"
    "scripts/security/setup_harden_system.sh:setup_harden_system"
    "scripts/security/setup_harden_network.sh:setup_harden_network"
    "scripts/setup_uki.sh:setup_uki"
    "scripts/build/custom/build_custom_packages.sh:build_custom_packages"
    "scripts/setup_desktop.sh:setup_desktop"
    "scripts/security/selinux/setup_selinux.sh:setup_selinux"
#    "scripts/kernel/setup_harden_kernel.sh:setup_harden_kernel"
)

info "Detecting Linux distribution"

detect_distribution

success "Distribution: $DISTRO"

info "Detecting package manager"

detect_package_manager

success "Package manager: $PACKAGE_MANAGER"

for entry in "${SETUP_SCRIPTS[@]}"; do
    IFS=':' read -r script function <<< "$entry"

    info "Running $(basename "$script")"

    source "$ROOT_DIR/$script"

    "$function"
done

success "Your linux is secured now. Reboot now for those changes to take effect."
