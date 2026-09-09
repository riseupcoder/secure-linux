#!/usr/bin/env bash

require_file() {
    [[ -f "$1" ]] || fail "File not found: $1"
}

require_directory() {
    [[ -d "$1" ]] || fail "Directory not found: $1"
}
