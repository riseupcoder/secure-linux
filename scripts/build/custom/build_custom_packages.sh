#!/usr/bin/env bash

set -euo pipefail

source "$SCRIPTS_DIR/build/custom/build_dwl.sh"
source "$SCRIPTS_DIR/build/custom/build_wlroots.sh"
source "$SCRIPTS_DIR/build/custom/build_pipewire.sh"

build_custom_packages() {
    build_dwl
    build_wlroots
    build_pipewire
}
