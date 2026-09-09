#!/usr/bin/env bash

info() {
    printf '[INFO] %s\n' "$*"
}

success() {
    printf '[ OK ] %s\n' "$*"
}

warn() {
    printf '[WARN] %s\n' "$*" >&2
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
}
