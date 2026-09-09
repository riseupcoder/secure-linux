#--ro-bind /usr/lib64/libhardened_malloc.so /usr/lib64/libhardened_malloc.so \
#--setenv LD_PRELOAD  /usr/lib64/libhardened_malloc.so \

bwrap \
  --ro-bind /usr /usr \
  --symlink usr/lib64 /lib64 \
  --symlink usr/bin /bin \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /home/user/Downloads \
  --bind "$HOME/.mullvad-browser" /home/user/.mullvad-browser \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --cap-drop all \
  --setenv HOME "/home/user" \
  --setenv USER "user" \
  --setenv XDG_RUNTIME_DIR "/run/user/$(id -u)" \
  --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
  --ro-bind "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR" \
  --dev-bind /dev/dri/card1 /dev/dri/card1 \
  --dev-bind /dev/dri/renderD128 /dev/dri/renderD128 \
  --ro-bind /sys/dev/char /sys/dev/char \
  --ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00 \
  --ro-bind /dev/snd /dev/snd \
  --unshare-all \
  --share-net \
  --die-with-parent \
  --new-session \
  /usr/bin/mullvad-browser
