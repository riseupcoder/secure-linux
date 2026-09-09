#!/usr/bin/env bash

DISTRO=""

detect_distribution() {

    [[ -f /etc/os-release ]] ||
        fail "/etc/os-release not found"

    . /etc/os-release

    DISTRO="$ID"
}
