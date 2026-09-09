#!/usr/bin/env bash

set -euo pipefail

install_doas() {

    info "Installing doas"

    case "$PACKAGE_MANAGER" in
        dnf)
            grep -q 'install_weak_deps=False' /etc/dnf/dnf.conf ||
                echo 'install_weak_deps=False' | sudo tee -a /etc/dnf/dnf.conf >/dev/null
            sudo -i dnf install -y doas
            ;;

        apt)
            sudo apt update
            sudo apt install -y doas
            ;;

        pacman)
            sudo pacman -S --noconfirm doas
            ;;

        *)
            fail "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
}

configure_doas() {

    echo "permit persist $USER" | sudo tee /etc/doas.conf >/dev/null
    doas chmod 400 /etc/doas.conf

    doas true || fail "doas setup failed"
}

remove_sudo() {
    info "Removing sudo"

    if [[ "$DISTRO" == "fedora" ]]; then
        doas rm -f /etc/dnf/protected.d/sudo.conf
        doas dnf remove -y --setopt=protected_packages= sudo
        remove_packages sudo-python-plugin
    else
        remove_packages sudo
    fi

    success "sudo removed"
}

setup_doas() {
    install_doas
    configure_doas

    remove_sudo 

    success "doas configured"
}
