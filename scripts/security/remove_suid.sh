#!/usr/bin/env bash

readonly IGNORE_SETUID_LIST=(
    "/usr/lib64/libhardened_malloc-light.so"
    "/usr/lib64/libhardened_malloc.so"
    "/usr/lib64/libno_rlimit_as.so"
    "/usr/bin/doas"
)

should_remove_setuid() {
    local binary="$1"
    local allowed_binary

    for allowed_binary in "${IGNORE_SETUID_LIST[@]}"; do
        if [[ "$binary" == "$allowed_binary" ]]; then
            return 1
        fi
    done

    return 0
}

remove_setuid_bits() {
    doas find /usr -type f -perm /6000 -print0 |
        while IFS= read -r -d '' binary; do
            if should_remove_setuid "$binary"; then
                info "Removing setuid/setgid bits from $binary"
                doas chmod ug-s "$binary"
            fi
        done
}

remove_unwanted_binaries() {
    local binaries=(
        "/usr/bin/chsh"
        "/usr/bin/chfn"
        "/usr/bin/pkexec"
        "/usr/bin/sudo"
        "/usr/bin/su"
    )

    doas rm -f "${binaries[@]}"
}

set_capability_if_present() {
    local caps="$1"
    local binary_path="$2"

    if [[ -f "$binary_path" ]]; then
        info "Setting capabilities $caps on $binary_path"
        doas setcap "$caps" "$binary_path"
        success "Set capabilities $caps on $binary_path"
    fi
}

set_required_capabilities() {
    set_capability_if_present \
        "cap_sys_admin=ep" \
        "/usr/bin/fusermount3"

    set_capability_if_present \
        "cap_dac_read_search,cap_audit_write=ep" \
        "/usr/sbin/unix_chkpwd"

    set_capability_if_present \
        "cap_fowner=ep" \
        "/usr/libexec/spice-gtk-$(uname -m)/spice-client-glib-usb-acl-helper"
}

remove_setuid() {
    info "Removing unwanted setuid/setgid permissions"

    remove_setuid_bits
    remove_unwanted_binaries
    set_required_capabilities

    success "setuid/setgid hardening completed"
}

