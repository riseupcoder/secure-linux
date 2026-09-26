#!/usr/bin/env bash
set -euo pipefail

export CFLAGS="-march=native"
export CXXFLAGS="-march=native"

SRC="$HOME/src"

SWAY_VERSION="1.12"

WLROOTS_REPO="https://gitlab.freedesktop.org/wlroots/wlroots.git"
SWAY_REPO="https://github.com/swaywm/sway.git"

install_build_deps() {
    doas dnf install -y \
        git meson ninja-build gcc-c++ pkgconf-pkg-config libevdev-devel \
        libdrm-devel mesa-libgbm-devel libinput-devel libxkbcommon-devel \
        pixman-devel libseat-devel hwdata-devel libdisplay-info-devel \
        libliftoff-devel libglvnd-devel wayland-devel wayland-protocols-devel \
        pcre2-devel json-c-devel pango-devel cairo-devel \
        vulkan-loader-devel vulkan-headers glslang-devel
}

install_runtime_deps() {
    doas dnf install -y \
        libdrm mesa-libgbm mesa-libEGL libglvnd-gles libinput libxkbcommon pixman libseat libglvnd libevdev \
        hwdata libdisplay-info libliftoff libwayland-server pcre2 json-c \
        pango cairo vulkan-loader
}

remove_build_deps() {
    echo "Removing build-only packages..."

    doas dnf remove -y \
        git meson ninja-build gcc-c++ \
        libdrm-devel mesa-libgbm-devel libinput-devel libglvnd-devel libevdev-devel \
        libxkbcommon-devel pixman-devel libseat-devel hwdata-devel \
        libdisplay-info-devel libliftoff-devel wayland-devel \
        wayland-protocols-devel pcre2-devel json-c-devel pango-devel \
        cairo-devel vulkan-loader-devel vulkan-headers glslang-devel
}

get_latest_wlroots() {
    cd "$SRC/wlroots"

    git fetch --tags --force

    WLROOTS_VERSION="$(
        git tag --list '0.20.*' --sort=-version:refname |
        head -n 1
    )"

    if [[ -z "$WLROOTS_VERSION" ]]; then
        echo "ERROR: Could not find a stable wlroots 0.20.x tag."
        exit 1
    fi

    echo "Latest stable wlroots 0.20.x: $WLROOTS_VERSION"

    git checkout --detach "$WLROOTS_VERSION"

    export WLROOTS_VERSION
}

build_wlroots() {
    cd "$SRC"

    rm -rf wlroots

    git clone "$WLROOTS_REPO" wlroots

    cd wlroots

    get_latest_wlroots

    echo "Building wlroots $WLROOTS_VERSION"

    meson setup \
        --prefix=/usr \
        --buildtype=release \
        -Dxwayland=disabled \
        -Dxcb-errors=disabled \
        -Dexamples=false \
        -Drenderers=gles2 \
        -Dbackends=drm,libinput \
        -Dallocators=gbm \
        -Dsession=auto \
        -Dcolor-management=auto \
        -Dlibliftoff=auto \
        build/

    ninja -C build/
    doas ninja -C build/ install

    doas ldconfig
}

build_sway() {
    cd "$SRC"

    rm -rf sway

    git clone "$SWAY_REPO" sway

    cd sway

    git fetch --tags --force
    git checkout --detach "$SWAY_VERSION"

    echo "Building Sway $SWAY_VERSION"
    echo "Using wlroots $WLROOTS_VERSION"

    meson setup \
        --prefix=/usr/local \
        --buildtype=release \
        -Ddefault-wallpaper=false \
        -Dzsh-completions=false \
        -Dbash-completions=false \
        -Dfish-completions=false \
        -Dswaybar=false \
        -Dswaynag=false \
        -Dtray=disabled \
        -Dgdk-pixbuf=disabled \
        -Dman-pages=disabled \
        -Dsd-bus-provider=auto \
        build/

    ninja -C build/
    doas ninja -C build/ install

    doas ldconfig
}

configure_vulkan_renderer() {
    echo "Configuring Vulkan renderer..."

    doas mkdir -p /etc/profile.d

    doas tee /etc/profile.d/sway-vulkan.sh >/dev/null <<'EOF'
export WLR_RENDERER=vulkan
EOF

    doas chmod 644 /etc/profile.d/sway-vulkan.sh
}

main() {
    mkdir -p "$SRC"

    install_build_deps
    build_wlroots
    build_sway
    # configure_vulkan_renderer

    remove_build_deps

    install_runtime_deps

    echo "Sway wm installed succesfully."
}

main
