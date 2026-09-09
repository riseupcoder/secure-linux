bwrap \
  --unshare-all \
  --new-session \
  --cap-drop all \
  --die-with-parent \
  --ro-bind /usr /usr \
  --ro-bind /lib64 /lib64 \
  --tmpfs /tmp \
  --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR" \
  --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
  --bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" \
  --ro-bind /usr/lib64/libhardened_malloc.so /usr/lib64/libhardened_malloc.so \
  --setenv LD_PRELOAD /usr/lib64/libhardened_malloc.so \
  wlsunset -l LAT -L LON -T 4500 -t 4000
