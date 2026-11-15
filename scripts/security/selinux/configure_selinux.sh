#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/system/selinux/sebool.conf"
readonly SELINUX_DIR="$SCRIPTS_DIR/security/selinux"
readonly SEPOLICY_REPO="https://github.com/riseupcoder/selinux-policy"

harden_userns() {
    info "Installing harden userns SELinux policy"

    install_selinux_cil "$SELINUX_DIR/harden_userns/harden_userns.cil"
    install_selinux_cil "$SELINUX_DIR/harden_userns/userns_deny_unconfined_relabels.cil"
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
        install_selinux_cil "$module"
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

install_custom_sepolicies() {

  install_packages git selinux-policy-devel

  create_temp_directory

  git clone "$SEPOLICY_REPO" "$TEMP_DIR/selinux-policy"

  (
      cd "$TEMP_DIR/selinux-policy"

      doas cp "wayland/wayland.if" "dwl/dwl.if" "seatd/seatd.if" /usr/share/selinux/devel/include/distributed/
      doas chmod 444 /usr/share/selinux/devel/include/distributed/*

      install_selinux_policy wayland wayland 
      install_selinux_policy seatd seatd 
      install_selinux_policy dwl dwl
      install_selinux_policy dwl_roles dwl
  )

  remove_temp_directory

  success "Custom selinux policy installed"
}

configure_selinux() {
    harden_userns
    deny_sockets
    harden_sebool
    install_custom_sepolicies

    success "SELinux configuration completed"
}
