#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/system/selinux/sebool.conf"

readonly SELINUX_DIR="$SCRIPTS_DIR/security/selinux"

harden_userns() {
    info "Installing harden userns SELinux policy"

    doas semodule -i "$SELINUX_DIR/harden_userns/harden_userns.cil"
    doas semodule -i "$SELINUX_DIR/harden_userns/userns_deny_unconfined_relabels.cil"
}

deny_sockets() {
    local modules=(
        "$SELINUX_DIR/sockets/socket_utils.cil"
        "$SELINUX_DIR/sockets/deny_packet_radio_sockets.cil"
        "$SELINUX_DIR/sockets/deny_obscure_sockets.cil"
        "$SELINUX_DIR/sockets/deny_ipsec_sockets.cil"
        "$SELINUX_DIR/sockets/deny_alg_sockets.cil"
    )

    info "Installing socket SELinux policies"

    for module in "${modules[@]}"; do
        info "Installing $(basename "$module")"
        doas semodule -i "$module"
    done
}

set_boolean() {
    local boolean="$1"
    local state="$2"

    if getsebool -a | grep "^$boolean" >/dev/null; then
        info "Setting $boolean -> $state"
        doas setsebool -P "$boolean" "$state"
    else
        warn "SELinux boolean not found: $boolean"
    fi
}

harden_sebool() {
    info "Hardening SELinux booleans"

    for boolean in "${BOOLS_ON[@]}"; do
        set_boolean "$boolean" on
    done

    for boolean in "${BOOLS_OFF[@]}"; do
        set_boolean "$boolean" off
    done
}

setup_harden_selinux() {
    harden_userns
    deny_sockets
    harden_sebool

    success "SELinux configuration completed"
}
