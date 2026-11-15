#!/usr/bin/env bash

set -euo pipefail

source "$SCRIPTS_DIR/security/selinux/configure_selinux.sh"
source "$SCRIPTS_DIR/security/selinux/setup_selinux_users.sh"

setup_selinux() {
    configure_selinux
    setup_selinux_users
}
