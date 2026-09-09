#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/hardened_malloc.conf"

readonly HARDENED_MALLOC_REPO="https://github.com/GrapheneOS/hardened_malloc"
readonly HOSTS_BLOCKLIST_URL="https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts"

install_hardened_malloc() {
    info "Installing hardened malloc"

    create_temp_directory

    install_packages "${HARDENED_MALLOC_BUILD_PACKAGES[@]}"

    info "Cloning hardened malloc from $HARDENED_MALLOC_REPO"

    git clone "$HARDENED_MALLOC_REPO" "$TEMP_DIR/hardened_malloc"

    (
        cd "$TEMP_DIR/hardened_malloc"

        make VARIANT=default

        doas install -m 755 out/libhardened_malloc.so /usr/lib64/
    )

    echo "/usr/lib64/libhardened_malloc.so" | doas tee /etc/ld.so.preload >/dev/null
    doas chmod 444 /etc/ld.so.preload

    echo "vm.max_map_count = 1048576" | doas tee /etc/sysctl.d/hardened_malloc.conf >/dev/null
    doas chmod 444 /etc/sysctl.d/hardened_malloc.conf

    remove_packages "${HARDENED_MALLOC_BUILD_PACKAGES[@]}"

    success "hardened malloc installed"
}

#!/usr/bin/env bash

setup_account_hardening() {
    info "Hardening user accounts"

    # Disable root password login
    doas passwd -dl root 2>/dev/null || true

    # Restrictive default umask
    if ! grep -q 'umask 0077' /etc/profile; then
        echo 'umask 0077' | doas tee -a /etc/profile >/dev/null
    fi

    # Restrict su to wheel users
    local pam_wheel='auth required pam_wheel.so use_uid'

    if ! grep -qF "$pam_wheel" /etc/pam.d/su; then
        echo "$pam_wheel" | doas tee -a /etc/pam.d/su >/dev/null
    fi

    if ! grep -qF "$pam_wheel" /etc/pam.d/su-l; then
        echo "$pam_wheel" | doas tee -a /etc/pam.d/su-l >/dev/null
    fi

    # Password hashing configuration
    local pam_password='password required pam_unix.so sha512 shadow nullok rounds=65536'

    if ! grep -qF "$pam_password" /etc/pam.d/passwd; then
        echo "$pam_password" | doas tee -a /etc/pam.d/passwd >/dev/null
    fi

    info "Password hashing rounds increased to 65536"
    info "Please set your password again for the new hashing to take effect"

    doas passwd "$USER"
}

setup_kernel_hardening() {
    info "Applying kernel hardening"

    require_file "$CONFIG_DIR/system/sysctl/harden_sysctl.conf"
    doas install -m 444 -C \
        "$CONFIG_DIR/system/sysctl/harden_sysctl.conf" \
        /etc/sysctl.d/

    require_file "$CONFIG_DIR/system/modprobe/blacklist.conf"
    doas install -m 444 -C \
        "$CONFIG_DIR/system/modprobe/blacklist.conf" \
        /etc/modprobe.d/

    doas chmod 700 \
        /boot \
        /usr/src \
        /lib/modules \
        /usr/lib/modules

    doas rfkill block all
}

setup_system_configuration() {
    info "Applying system configuration"

    echo "b08dfa6083e7567a1921a715000001fb" |
        doas tee /etc/machine-id >/dev/null

    echo "localhost" |
        doas tee /etc/hostname >/dev/null

    curl -fsSL --tlsv1.3 "$HOSTS_BLOCKLIST_URL" |
        doas tee -a /etc/hosts >/dev/null
}

setup_networkmanager_hardening() {
    [[ "$(cat /proc/1/comm)" == "systemd" ]] || return 0

    info "Hardening NetworkManager"

    doas install -Dm444 -C \
        "$CONFIG_DIR/system/systemd/NetworkManager/40-sandbox.conf" \
        /etc/systemd/system/NetworkManager.service.d/40-sandbox.conf

    doas install -Dm444 -C \
        "$CONFIG_DIR/system/systemd/NetworkManager/40-killmode.conf" \
        /etc/systemd/system/NetworkManager.service.d/40-killmode.conf

    doas systemctl daemon-reload
    doas systemctl restart NetworkManager
}

setup_harden_system() {
    info "Applying system hardening"

    setup_account_hardening
    setup_kernel_hardening
    setup_system_configuration
    setup_networkmanager_hardening

    install_hardened_malloc

    success "System hardening complete"
}


