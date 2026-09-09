# 1. Install required tools
doas dnf install -y dracut sbsigntools efitools openssl binutils systemd-boot

# 2. Set kernel parameters
doas mkdir -p /etc/kernel/cmdline.d
echo "root=UUID=$(findmnt -n -o UUID /) rw slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 pti=on randomize_kstack_offset=on vsyscall=none debugfs=off oops=panic module.sig_enforce=1 lockdown=confidentiality mce=0 quiet loglevel=0 slub_debug=FZP hardened_usercopy=1 hash_pointers=always iommu.passthrough=0 iommu.strict=1 vdso32=0 cfi=kcfi random.trust_cpu=off random.trust_bootloader=off amd_iommu=on iommu=force rd.shell=0 rd.emergency=halt systemd.ssh_auto=no security=selinux selinux=1 proc_mem.force_override=never ia32_emulation=0 kvm.mitigate_smt_rsb=1 efi=disable_early_pci_dma ipv6.disable=1" | doas tee /etc/kernel/cmdline.d/cmdline.conf

 BUILT_VERSION="$(uname -r)"

  # 3. Build UKI
  doas dracut \
    --force \
    --uefi \
    --kver "$BUILT_VERSION" \
    --kernel-cmdline "@/etc/kernel/cmdline.d/cmdline.conf" \
    "/boot/efi/EFI/BOOT/BOOTX64-$BUILT_VERSION.EFI"

  # 4. Generate keys directly in /etc/efikeys using full paths
  doas mkdir -p /etc/efikeys
  uuidgen --random | doas tee /etc/efikeys/GUID.txt > /dev/null   

# Generate Platform Key (PK)
doas openssl req -new -x509 -newkey rsa:4096 \
  -keyout /etc/efikeys/PK.key -out /etc/efikeys/PK.crt \
  -days 1095 -nodes -sha512 \
  -subj "/CN=My Custom Platform Key/"

# Generate Key Exchange Key (KEK)
doas openssl req -new -x509 -newkey rsa:4096 \
  -keyout /etc/efikeys/KEK.key -out /etc/efikeys/KEK.crt \
  -days 1095 -nodes -sha512 \
  -subj "/CN=My Custom KEK/"

# Generate Signature Database Key (db) — your original key
doas openssl req -new -x509 -newkey rsa:4096 \
  -keyout /etc/efikeys/db.key -out /etc/efikeys/db.crt \
  -days 1095 -nodes -sha512 -subj "/CN=Fedora UKI Key"

# 5. Convert certs to EFI Signature List (.esl)
doas cert-to-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" /etc/efikeys/PK.crt /etc/efikeys/PK.esl
doas cert-to-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" /etc/efikeys/KEK.crt /etc/efikeys/KEK.esl
doas cert-to-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" /etc/efikeys/db.crt /etc/efikeys/db.esl

  # 6. Sign the UKI
  UKI_PATH="/boot/efi/EFI/BOOT/BOOTX64-$BUILT_VERSION.EFI"

  doas sbsign \
    --key /etc/efikeys/db.key \
    --cert /etc/efikeys/db.crt \
    --output "$UKI_PATH" \
    "$UKI_PATH"

# 7. Create authenticated update files (.auth)
doas sign-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" \
  -k /etc/efikeys/PK.key -c /etc/efikeys/PK.crt PK /etc/efikeys/PK.esl /etc/efikeys/PK.auth

doas sign-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" \
  -k /etc/efikeys/PK.key -c /etc/efikeys/PK.crt KEK /etc/efikeys/KEK.esl /etc/efikeys/KEK.auth

doas sign-efi-sig-list -g "$(doas cat /etc/efikeys/GUID.txt)" \
  -k /etc/efikeys/KEK.key -c /etc/efikeys/KEK.crt db /etc/efikeys/db.esl /etc/efikeys/db.auth

# 8. Copy all keys to ESP
doas mkdir -p /boot/efi/keys
doas cp /etc/efikeys/KEK.auth /boot/efi/keys/
doas cp /etc/efikeys/db.auth /boot/efi/keys/
doas cp /etc/efikeys/PK.auth /boot/efi/keys/

# 9. Enroll keys via firmware (manual step)
echo "Reboot and enroll keys in UEFI Setup in this order:"
echo "1. Enroll KEK.auth → KEK"
echo "2. Enroll db.auth → db"
echo "3. Enroll PK.auth → PK (activates User Mode)"

doas efibootmgr \
    --create \
    --disk /dev/nvme0n1 \
    --part 1 \
    --loader "\\EFI\\BOOT\\BOOTX64-$BUILT_VERSION.EFI" \
    --label "Distro Kernel $BUILT_VERSION" \
    --verbose

echo "UKI EFI BOOT setup successfully."

#doas efibootmgr --bootorder 0002,0000,0001

#doas rm /etc/dnf/protected.d/{grub2-,shim}*
#doas dnf remove grub2* shim*
#doas rm -rf /boot/grub2 /boot/loader /boot/efi/EFI/fedora

#Remove GRUB from UEFI boot manager: List entries:
#doas efibootmgr

#Identify the GRUB entry (e.g., Boot0001) and remove it:
#doas efibootmgr -Bb XXXX

#(Optional) Clean up initramfs and vmlinuz files in /boot: If using UKI, traditional kernel images may be redundant:
#doas rm /boot/vmlinuz-* /boot/initramfs-*

#doas mkdir -p /boot/efi/EFI/boot

#doas dnf remove systemd-boot-unsigned binutils sbsigntools
