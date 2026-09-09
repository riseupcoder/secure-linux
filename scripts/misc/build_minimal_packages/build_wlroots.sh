#!/bin/bash

set -euo pipefail

build_wlroots() {
  # Install build dependencies
  doas dnf install -y \
    git meson ninja-build gcc-c++ \
    libdrm-devel libinput-devel mesa-libgbm-devel pixman-devel \
    wayland-devel wayland-protocols-devel \
    libxkbcommon-devel libseat-devel libglvnd-devel hwdata-devel libdisplay-info-devel libliftoff-devel

  git clone https://gitlab.freedesktop.org/wlroots/wlroots.git
  cd wlroots
  git fetch --tags
  tag=$(git tag -l "0.19.*" | sort -Vr | head -n1)
  echo "Cloning and checking out tag: $tag"
  git checkout $tag

  # Configure with Meson for a minimal, secure build
  CFLAGS="-march=native" CXXFLAGS="-march=native" meson setup \
    --prefix=/usr \
    --buildtype=release \
    -Dxwayland=disabled \
    -Dxcb-errors=disabled \
    -Dexamples=false \
    -Drenderers=gles2 \
    -Dbackends=drm,libinput \
    -Dallocators=gbm \
    -Dsession=auto \
    -Dcolor-management=disabled \
    -Dlibliftoff=auto \
    build

  ninja -C build
  doas ninja -C build install

  # Remove build dependencies
  doas dnf remove \
    git meson ninja-build gcc-c++ \
    libdrm-devel libinput-devel mesa-libgbm-devel pixman-devel \
    wayland-devel wayland-protocols-devel \
    libxkbcommon-devel libseat-devel libglvnd-devel hwdata-devel libdisplay-info-devel libliftoff-devel

  # Install runtime dependencies
  doas dnf install \
    libdrm libinput mesa-libgbm pixman \
    libxkbcommon libseat libglvnd hwdata libdisplay-info libliftoff
}

build_wlroots
