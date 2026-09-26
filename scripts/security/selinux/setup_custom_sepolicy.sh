#!/usr/bin/env bash

set -euo pipefail

readonly SEPOLICY_REPO="https://github.com/riseupcoder/selinux-policy"

setup_custom_sepolicy() {

  create_temp_directory

  git clone "$SEPOLICY_REPO" "$TEMP_DIR/selinux-policy"

  (
      cd "$TEMP_DIR/selinux-policy"

      doas cp "wayland/wayland.if" "dwl/dwl.if" "seatd/seatd.if" /usr/share/selinux/devel/include/distributed/
      doas chmod 444 /usr/share/selinux/devel/include/distributed/*

      install_selinux_policy wayland wayland 
      install_selinux_policy seatd seatd 
      install_selinux_policy dwl dwl
      install_selinux_policy dwl_roles dwl
      install_selinux_policy user_dwl dwl
  )

  success "Custom selinux policy installed"
}
