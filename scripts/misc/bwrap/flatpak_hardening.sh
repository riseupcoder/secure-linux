
flatpak_hardening() {

  # only allow verified flatpak apps to be installed.

  flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak remote-modify --subset=verified flathub
  flatpak --user remote-modify --subset=verified flathub

  # Globally removing unncessary stuff like X11, Networking and IPC Permission, 
  # removing filesystem access to host system

  flatpak --user override \
  --nosocket=x11 --nosocket=fallback-x11 \
  --nosocket=pulseaudio --nosocket=cups --nosocket=pcsc \
  --nosocket=session-bus --nosocket=system-bus \
  --unshare=network --unshare=ipc \
  --nofilesystem=host --nofilesystem=host-os --nofilesystem=home \
  --no-talk-name=org.freedesktop.Flatpak \
  --no-talk-name=org.freedesktop.systemd1 \
  --no-talk-name=ca.desrt.dconf \
  --no-talk-name=org.gnome.Shell.Extensions

  # enable hardened_malloc support for all flatpak apps by default make sure to install hardened_malloc first before running this script

  mkdir -p "$HOME/.local/lib"
  install -m 755 /usr/lib64/libhardened_malloc.so "$HOME/.local/lib/"

  flatpak --user override --env=LD_PRELOAD=/home/$USER/.local/lib/libhardened_malloc.so --filesystem=~/.local/lib:ro

  echo "[+] Flatpak setup completed"
}

flatpak_hardening
