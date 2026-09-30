#!/usr/bin/env bash

set -euo pipefail

source "$CONFIG_DIR/packages/$DISTRO/pipewire.conf"

readonly PW_REPO="https://gitlab.freedesktop.org/pipewire/pipewire.git"
readonly WP_REPO="https://gitlab.freedesktop.org/pipewire/wireplumber.git"

build_pipewire() {

  # Install PipeWire build dependencies
  install_packages "${PW_BUILD_PACKAGES[@]}" git pkgconf-pkg-config libudev-devel

  create_temp_directory

  git clone --depth 1 "$PW_REPO" "$TEMP_DIR/pipewire"

  # Build PipeWire
  (
    cd "$TEMP_DIR/pipewire"

    info "Configuring PipeWire"

    meson setup build \
      --prefix=/usr \
      --buildtype=release \
      -Ddocs=disabled \
      -Dman=disabled \
      -Dexamples=disabled \
      -Dtests=disabled \
      -Dinstalled_tests=disabled \
      -Dpipewire-alsa=disabled \
      -Dpipewire-jack=disabled \
      -Dpipewire-v4l2=disabled \
      -Dsession-managers=wireplumber \
      -Dgstreamer=disabled \
      -Dffmpeg=disabled \
      -Dbluez5=disabled \
      -Dlibcamera=disabled \
      -Dv4l2=disabled \
      -Dx11=disabled \
      -Dx11-xfixes=disabled \
      -Dvulkan=disabled \
      -Dlibpulse=enabled \
      -Dpw-cat=disabled \
      -Droc=disabled \
      -Draop=disabled \
      -Davahi=disabled \
      -Dlv2=disabled \
      -Dlibusb=disabled \
      -Dflatpak=disabled \
      -Dsnap=disabled \
      -Dselinux=enabled \
      -Ddbus=disabled \
      -Dudev=enabled \
      -Davb=disabled \
      -Dtest=disabled \
      -Dvideotestsrc=disabled \
      -Dvolume=disabled \
      -Dpw-cat-ffmpeg=disabled \
      -Decho-cancel-webrtc=disabled \
      -Dlegacy-rtkit=false \
      -Davb-virtual=disabled \
      -Dreadline=disabled \
      -Dgsettings=disabled \
      -Dgsettings-pulse-schema=disabled \
      -Dbluez5-backend-hsp-native=disabled \
      -Dbluez5-backend-hfp-native=disabled \
      -Dbluez5-backend-native-mm=disabled \
      -Dbluez5-backend-ofono=disabled \
      -Dbluez5-backend-hsphfpd=disabled \
      -Dbluez5-codec-aptx=disabled \
      -Dbluez5-codec-ldac=disabled \
      -Dbluez5-codec-ldac-dec=disabled \
      -Dbluez5-codec-aac=disabled \
      -Dbluez5-codec-lc3plus=disabled \
      -Dbluez5-codec-opus=disabled \
      -Dbluez5-codec-lc3=disabled \
      -Dbluez5-codec-g722=disabled \
      -Dbluez5-plc-spandsp=disabled \
      -Dsystemd-system-service=disabled \
      -Daudiotestsrc=disabled \
      -Dsystemd-user-service=enabled \
      -Dlibsystemd=disabled \
      -Dlogind=disabled

    ninja -C build
    doas ninja -C build install
  )

  # Build WirePlumber
  git clone --depth 1 "$WP_REPO" "$TEMP_DIR/wireplumber"

  (
    cd "$TEMP_DIR/wireplumber"

    info "Configuring WirePlumber"

    meson setup build \
      --prefix=/usr \
      --buildtype=release \
      -Dintrospection=disabled \
      -Dsystem-lua=true \
      -Dsystemd=disabled \
      -Delogind=disabled \
      -Dsystemd-system-service=false \
      -Dsystemd-user-service=true \
      -Dtests=false \
      -Ddbus-tests=false \
      -Dglib-supp=''

    ninja -C build
    doas ninja -C build install
  )

  # Remove build dependencies
  remove_packages "${PW_BUILD_PACKAGES[@]}"

  # Install PipeWire/WirePlumber runtime dependencies
  install_packages "${PW_RUNTIME_PACKAGES[@]}"

  # create necessary dirs before enabling systemd user service for pipewire and wireplumber
  mkdir -p "$HOME/.config/systemd/user/default.target.wants/" "$HOME/.config/systemd/user/sockets.target.wants/" "$HOME/.config/systemd/user/pipewire.service.wants/"

  # Reload and enable PipeWire user services
  systemctl --user daemon-reload
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  systemctl --user start pipewire pipewire-pulse wireplumber

  success "PipeWire and WirePlumber installed"
}

