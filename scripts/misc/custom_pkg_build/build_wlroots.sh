#!/bin/bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/wlroots.conf"
readonly WLR_REPO="https://gitlab.freedesktop.org/wlroots/wlroots.git"

build_wlroots() {

  # Install wlroots build deps
  install_packages "${WLR_BUILD_PACKAGES[@]}"

  create_temp_directory

  git clone "$WLR_REPO" "$TEMP_DIR/wlroots"
 
  (
    cd "$TEMP_DIR/wlroots"

    git fetch --tags
    tag=$(git tag -l "0.20.*" | sort -Vr | head -n1)

    info "Cloning and checking out tag: $tag"
    git checkout $tag

    # Configure with Meson for a minimal, secure build
    CFLAGS="-march=native" CXXFLAGS="-march=native" meson setup \
      --prefix=/usr \
      --buildtype=release \
      -Dxwayland=disabled \
      -Dxcb-errors=disabled \
      -Dexamples=false \
      -Drenderers=auto \
      -Dbackends=drm,libinput \
      -Dallocators=gbm \
      -Dsession=auto \
      -Dcolor-management=auto \
      -Dlibliftoff=auto \
      build

      ninja -C build
      doas ninja -C build install
  )

  # Remove wlroots build deps
  remove_packages "${WLR_BUILD_PACKAGES[@]}"

  # Install wlroots runtime deps
  install_packages "${WLR_RUNTIME_PACKAGES[@]}"

  success "wlroots installed"
}
