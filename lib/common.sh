#!/usr/bin/env bash

readonly CONFIG_DIR="$ROOT_DIR/config"
readonly SCRIPTS_DIR="$ROOT_DIR/scripts"
#readonly LIB_DIR="$ROOT_DIR/lib"

TEMP_DIR=""

create_temp_directory() {
    TEMP_DIR="$(mktemp -d)"
}

remove_temp_directory() {
    [[ -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

require_programs() {
    local program

    for program in "$@"; do
        command -v "$program" >/dev/null 2>&1 ||
            fail "Required program missing: $program"
    done
}
