#!/usr/bin/env bash

set -euo pipefail

install_selinux_module() {
    local module_file="$1"
    local file_name="${module_file##*/}"

    info "Installing SELinux module: $file_name"

    doas semodule -i "$module_file"

    success "SELinux module installed"
}

install_selinux_cil() {
    local cil_file="$1"
    local cil_name="${cil_file##*/}"

    info "Installing SELinux CIL module: $cil_name"

    doas semodule -i "$cil_file"

    success "SELinux CIL module installed: $cil_name"
}

install_selinux_policy() {
    local policy_name="$1"
    local policy_dir="$2"
    local selinux_dir

    echo
    info "Building SELinux policy: $policy_name"

    create_temp_directory

    selinux_dir="$TEMP_DIR/selinux"

    mkdir -p "$selinux_dir"

    if [[ -f $policy_dir/${policy_name}.fc ]]; then
      cp "$policy_dir/${policy_name}.fc" "$policy_dir/${policy_name}.te" "$selinux_dir"
    else
      cp "$policy_dir/${policy_name}.te" "$selinux_dir"
    fi

    (
        cd "$selinux_dir" || exit 1

        make -f /usr/share/selinux/devel/Makefile "${policy_name}.pp" >/dev/null
    )

    install_selinux_module "$selinux_dir/${policy_name}.pp"

    # remove_temp_directory "$TEMP_DIR"
    remove_temp_directory
}

