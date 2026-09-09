niri_setup() {
  doas dnf install -y gcc libudev-devel libgbm-devel libxkbcommon-devel wayland-devel libinput-devel dbus-devel systemd-devel libseat-devel pipewire-devel pango-devel cairo-gobject-devel clang libdisplay-info-devel git

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

  source "$HOME/.cargo/env"


  git clone https://github.com/niri-wm/niri
  cd niri/

  cargo build --release --no-default-features 

  # 1. Install the binaries
  doas cp target/release/niri /usr/local/bin/
  doas cp resources/niri-session /usr/local/bin/
  doas chmod +x /usr/local/bin/niri-session

  doas mkdir -p /usr/local/share/wayland-sessions/
  doas cp resources/niri.desktop /usr/local/share/wayland-sessions/

  # Remove devel deps
  doas dnf remove -y gcc libudev-devel libgbm-devel libxkbcommon-devel wayland-devel libinput-devel dbus-devel systemd-devel libseat-devel pipewire-devel pango-devel cairo-gobject-devel clang libdisplay-info-devel git

  # Install runtime deps
  doas dnf install -y libgudev libgbm libxkbcommon libwayland-server libinput libseat pango cairo-gobject libdisplay-info mesa-libEGL mesa-libgbm

}

remove_packages() {
  doas dnf remove libgudev libgbm libxkbcommon libwayland-server libinput libseat pango cairo-gobject libdisplay-info mesa-libEGL mesa-libgbm
}

remove_packages
