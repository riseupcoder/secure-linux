#!/usr/bin/env bash

set -euo pipefail

readonly ADMIN_USER="admin"
readonly CURRENT_USER="$USER"

setup_selinux_users() {
    info "Installing SELinux user management tools"

    install_packages policycoreutils-python-utils

    info "Configuring user_u roles"

    # staff_u
    # doas semanage user -m -R "staff_r container_user_r" staff_u

    # user_u
    doas semanage user -m -R "user_r container_user_r" -r s0-s0:c0.c1023 user_u

    doas chmod 600 /etc/doas.conf

    setup_admin_user
    setup_unprivileged_user

    cleanup

    success "SELinux users configured"
}

setup_admin_user() {
    if ! id "$ADMIN_USER" >/dev/null 2>&1; then
        info "Creating administration user"

        doas useradd -m -G wheel "$ADMIN_USER"

        doas passwd "$ADMIN_USER"
    fi

    info "Mapping admin user to sysadm_u"

    doas semanage user -m -R "sysadm_r" sysadm_u

    doas semanage login -a -s sysadm_u "$ADMIN_USER"

    doas grep -q "permit persist $ADMIN_USER" /etc/doas.conf ||
        echo "permit persist $ADMIN_USER" |
        doas tee -a /etc/doas.conf >/dev/null
}

setup_unprivileged_user() {
    info "Mapping current user to staff_u"

    doas semanage login -a -s user_u "$CURRENT_USER"
}

cleanup() {
    doas dnf remove -y policycoreutils-python-utils
    info "clean up finished"
}
