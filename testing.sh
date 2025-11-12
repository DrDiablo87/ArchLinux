#!/bin/bash
# quick-install.sh - Еще более минималистичная версия

set -e

DISK="/dev/nvme0n1"

# Разметка
wipefs -a $DISK
parted -s $DISK mklabel gpt
parted -s $DISK mkpart "EFI" fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart "root" 513MiB 100%

mkfs.fat -F32 "${DISK}p1"
mkfs.btrfs -f "${DISK}p2"

mount "${DISK}p2" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o subvol=@ "${DISK}p2" /mnt
mkdir -p /mnt/{home,boot}
mount -o subvol=@home "${DISK}p2" /mnt/home
mount "${DISK}p1" /mnt/boot

# Установка
pacstrap /mnt base linux linux-firmware btrfs-progs sudo
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot конфигурация
arch-chroot /mnt bash << EOF
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "arch" > /etc/hostname

echo "root:w" | chpasswd
useradd -m -G wheel -s /bin/bash user
echo "www:w" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

bootctl --path=/boot install
echo "default arch" > /boot/loader/loader.conf
echo "timeout 3" >> /boot/loader/loader.conf

cat > /boot/loader/entries/arch.conf << EOL
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value ${DISK}p2) rw rootflags=subvol=@
EOL

# Минимальный KDE
pacman -S --noconfirm plasma-desktop sddm dolphin konsole firefox
systemctl enable sddm NetworkManager
EOF

echo "Установка завершена!"
