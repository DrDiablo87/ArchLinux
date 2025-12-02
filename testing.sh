#!/bin/bash

# Минимальная установка Arch Linux с Btrfs, NVMe и KDE
# WARNING: Скрипт форматирует диски!

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Проверка UEFI
check_uefi() {
    if [ ! -d /sys/firmware/efi ]; then
        print_error "Требуется UEFI система"
        exit 1
    fi
}

# Выбор диска
select_disk() {
    print_info "Доступные диски:"
    lsblk -f
    
    if lsblk | grep -q nvme; then
        DISK="/dev/nvme0n1"
    else
        print_error "NVMe диск не найден!"
        exit 1
    fi
    
    print_warning "Будет отформатирован: $DISK"
    read -p "Продолжить? (y/N): " confirm
    [[ $confirm =~ ^[Yy]$ ]] || exit 0
}

# Создание разделов
create_partitions() {
    print_info "Создание разделов..."
    
    # Очистка диска
    wipefs -a $DISK
    
    # Создание разделов
    parted -s $DISK mklabel gpt
    parted -s $DISK mkpart "EFI" fat32 1MiB 513MiB
    parted -s $DISK set 1 esp on
    parted -s $DISK mkpart "root" 513MiB 100%
    
    # Форматирование
    if [[ $DISK == *"nvme"* ]]; then
        mkfs.fat -F32 "${DISK}p1"
        mkfs.btrfs -f "${DISK}p2"
        ROOT_PART="${DISK}p2"
        EFI_PART="${DISK}p1"
    else
        mkfs.fat -F32 "${DISK}1"
        mkfs.btrfs -f "${DISK}2"
        ROOT_PART="${DISK}2"
        EFI_PART="${DISK}1"
    fi
}

# Настройка Btrfs
setup_btrfs() {
    print_info "Настройка Btrfs..."
    
    mount $ROOT_PART /mnt
    
    # Только основные подтомы
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    
    umount /mnt
    
    # Монтирование
    mount -o noatime,compress=zstd,subvol=@ $ROOT_PART /mnt
    mkdir -p /mnt/home
    mount -o noatime,compress=zstd,subvol=@home $ROOT_PART /mnt/home
    mkdir -p /mnt/boot
    mount $EFI_PART /mnt/boot
}

# Настройка зеркал
setup_mirrors() {
    print_info "Настройка зеркал..."
    cat > /etc/pacman.d/mirrorlist << 'EOF'
Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF
}

# Установка базовой системы
install_base() {
    print_info "Установка базовой системы..."
    
    pacman -Sy --noconfirm archlinux-keyring
    pacstrap /mnt base base-devel linux linux-firmware \
               btrfs-progs sudo nano
    
    # Fstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

# Конфигурация системы в chroot
configure_system() {
    cat > /mnt/configure.sh << 'EOF'
#!/bin/bash
set -e

# Время и локали
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo "KEYMAP=ru" > /etc/vconsole.conf

# Сеть
echo "arch" > /etc/hostname
cat > /etc/hosts << 'EOL'
127.0.0.1   localhost
::1         localhost
127.0.1.1   arch.localdomain arch
EOL

# Initramfs
cat > /etc/mkinitcpio.conf << 'EOL'
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck btrfs)
EOL
mkinitcpio -P

# Загрузчик
bootctl --path=/boot install

cat > /boot/loader/loader.conf << 'EOL'
default arch
timeout 3
editor no
EOL

cat > /boot/loader/entries/arch.conf << 'EOL'
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value /dev/disk/by-partlabel/root) rw rootflags=subvol=@ quiet
EOL

# Пользователь
echo "root:w" | chpasswd
useradd -m -G wheel -s /bin/bash user
echo "www:w" | chpasswd
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Сеть
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

EOF

    chmod +x /mnt/configure.sh
    arch-chroot /mnt ./configure.sh
    rm /mnt/configure.sh
}

# Установка минимальной KDE
install_minimal_kde() {
    print_info "Установка минимальной KDE..."
    
    cat > /mnt/install_kde.sh << 'EOF'
#!/bin/bash
set -e

# Минимальный Xorg и KDE
pacman -S --noconfirm xorg-server xorg-xinit

# Базовая KDE Plasma
pacman -S --noconfirm plasma-desktop plasma-pa plasma-nm
pacman -S --noconfirm sddm dolphin konsole
pacman -S --noconfirm firefox noto-fonts ttf-dejavu

# Минимальные утилиты
pacman -S --noconfirm htop neofetch

# Включение SDDM
systemctl enable sddm

EOF

    chmod +x /mnt/install_kde.sh
    arch-chroot /mnt ./install_kde.sh
    rm /mnt/install_kde.sh
}

# Установка дополнительных драйверов
install_drivers() {
    print_info "Установка драйверов..."
    
    cat > /mnt/install_drivers.sh << 'EOF'
#!/bin/bash
set -e

# Драйвера для NVIDIA (если нужно)
# pacman -S --noconfirm nvidia nvidia-utils

# Драйвера для Intel/AMD
pacman -S --noconfirm mesa xf86-video-intel xf86-video-amdgpu

# Аудио
pacman -S --noconfirm pulseaudio pulseaudio-alsa

# Bluetooth
pacman -S --noconfirm bluez bluez-utils
systemctl enable bluetooth

EOF

    chmod +x /mnt/install_drivers.sh
    arch-chroot /mnt ./install_drivers.sh
    rm /mnt/install_drivers.sh
}

# Финальная настройка
final_setup() {
    print_info "Финальная настройка..."
    
    cat > /mnt/final.sh << 'EOF'
#!/bin/bash

# Создание ярлыков для пользователя
mkdir -p /home/user/.config/environment.d
echo "QT_QPA_PLATFORMTHEME=qt5ct" > /home/user/.config/environment.d/qt.conf

# Настройка прав
chown -R user:user /home/user

EOF

    chmod +x /mnt/final.sh
    arch-chroot /mnt ./final.sh
    rm /mnt/final.sh
}

# Основная функция
main() {
    print_info "Минимальная установка Arch Linux с Btrfs + KDE"
    
    check_uefi
    select_disk
    create_partitions
    setup_btrfs
    setup_mirrors
    install_base
    configure_system
    install_minimal_kde
    install_drivers
    final_setup
    
    print_info "Установка завершена!"
    print_info "Команды для перезагрузки:"
    print_info "umount -R /mnt"
    print_info "reboot"
    print_info ""
    print_info "После входа:"
    print_info "Логин: www"
    print_info "Пароль: w"
}

main "$@"
