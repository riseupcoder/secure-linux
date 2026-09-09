#!/usr/bin/env bash
set -euo pipefail

PREFIX="/usr"
SRC="$HOME/src"
BUILD="$HOME/build"

PW_SRC="$SRC/pipewire"
WP_SRC="$SRC/wireplumber"

PW_BUILD="$BUILD/pipewire"
WP_BUILD="$BUILD/wireplumber"

mkdir -p "$SRC" "$BUILD"

# Install build dependencies
doas dnf install -y git gcc gcc-c++ meson ninja-build cmake pkgconf-pkg-config \
    glib2-devel systemd-devel alsa-lib-devel libudev-devel libselinux-devel \
    lua-devel pulseaudio-libs-devel libselinux

# PipeWire
git clone --depth 1 https://gitlab.freedesktop.org/pipewire/pipewire.git "$PW_SRC"
rm -rf "$PW_BUILD"

meson setup "$PW_BUILD" "$PW_SRC" \
    --prefix="$PREFIX" \
    --buildtype=release \
    -Ddocs=disabled \
    -Dman=disabled \
    -Dexamples=disabled \
    -Dtests=disabled \
    -Dinstalled_tests=disabled \
    -Dsession-managers=wireplumber \
    -Dpipewire-alsa=disabled \
    -Dpipewire-jack=disabled \
    -Dpipewire-v4l2=disabled \
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
    -Dlibsystemd=disabled \
    -Dlogind=disabled \
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
    -Dtest=disabled \
    -Dvideotestsrc=disabled \
    -Dvolume=disabled \
    -Dpw-cat=disabled \
    -Dpw-cat-ffmpeg=disabled \
    -Decho-cancel-webrtc=disabled \
    -Dlegacy-rtkit=false \
    -Davb-virtual=disabled \
    -Dreadline=disabled \
    -Dgsettings=disabled \
    -Dgsettings-pulse-schema=disabled 

meson compile -C "$PW_BUILD"
doas meson install -C "$PW_BUILD"

# WirePlumber
git clone --depth 1 https://gitlab.freedesktop.org/pipewire/wireplumber.git "$WP_SRC"
rm -rf "$WP_BUILD"

meson setup "$WP_BUILD" "$WP_SRC" \
    --prefix="$PREFIX" \
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

meson compile -C "$WP_BUILD"
doas meson install -C "$WP_BUILD"

# Reset user services
rm -f ~/.config/systemd/user/pipewire.service \
      ~/.config/systemd/user/pipewire-pulse.service \
      ~/.config/systemd/user/wireplumber.service

systemctl --user daemon-reload
systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
systemctl --user restart pipewire pipewire-pulse wireplumber

# Remove build dependencies
doas dnf remove -y git gcc gcc-c++ meson ninja-build cmake \
    glib2-devel systemd-devel alsa-lib-devel libselinux-devel \
    lua-devel pulseaudio-libs-devel

# install minimal runtime deps for pipewire and pipewire-pulse to work
doas dnf install glib2 alsa-lib pulseaudio-libs libselinux rtkit
doas systemctl enable --now rtkit-daemon
