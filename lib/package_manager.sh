#!/usr/bin/env bash

PACKAGE_MANAGER=""

detect_package_manager() {
    if command -v dnf >/dev/null 2>&1; then
        PACKAGE_MANAGER="dnf"
    elif command -v apt >/dev/null 2>&1; then
        PACKAGE_MANAGER="apt"
    elif command -v pacman >/dev/null 2>&1; then
        PACKAGE_MANAGER="pacman"
    else
        die "Unsupported package manager"
    fi
}

install_packages() {
    case "$PACKAGE_MANAGER" in
        dnf)
            doas dnf install -y "$@"
            ;;
        apt)
            doas apt install -y "$@"
            ;;
        pacman)
            doas pacman -S --noconfirm "$@"
            ;;
        *)
            die "Package manager not detected"
            ;;
    esac
}

remove_packages() {
    case "$PACKAGE_MANAGER" in
        dnf)
            doas dnf remove -y "$@"
            ;;
        apt)
            doas apt remove -y "$@"
            ;;
        pacman)
            doas pacman -R --noconfirm "$@"
            ;;
        *)
            die "Package manager not detected"
            ;;
    esac
}
