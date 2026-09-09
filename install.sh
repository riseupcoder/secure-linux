#!/usr/bin/env bash

set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly LIB_DIR="$ROOT_DIR/lib"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/logging.sh"
source "$LIB_DIR/filesystem.sh"
source "$LIB_DIR/distro.sh"
source "$LIB_DIR/package_manager.sh"

readonly SETUP_SCRIPTS=(
    "scripts/setup_doas.sh:setup_doas"
    "scripts/misc/system/debloat_fedora.sh:debloat_fedora"
    "scripts/security/setup_harden_system.sh:setup_harden_system"
    "scripts/security/remove_suid.sh:remove_setuid"
    "scripts/setup_uki.sh:setup_uki"
    "scripts/setup_desktop.sh:setup_desktop"
    "scripts/security/selinux/setup_harden_selinux.sh:setup_harden_selinux"
    "scripts/security/selinux/setup_selinux_users.sh:setup_selinux_users"
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
