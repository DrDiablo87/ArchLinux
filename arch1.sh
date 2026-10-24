#!/usr/bin/env bash
# =============================================================================
# Arch Linux Dual Boot Install Script (Windows + Arch)
# - Btrfs root (no subvolumes)
# - systemd-boot (no GRUB)
# - Minimal KDE Plasma + SDDM autologin
# - Russian mirrors, AUR, archlinuxcn, chaotic-aur, blackarch
# - Empty bash script in autostart
# =============================================================================

set -euo pipefail

# ---------- 1. Запрос данных пользователя ----------
read -rp "Введите имя пользователя: " USERNAME
read -rsp "Введите пароль для пользователя $USERNAME: " USER_PASSWORD
echo
read -rsp "Подтвердите пароль: " USER_PASSWORD_CONFIRM
echo
if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
    echo "Ошибка: пароли не совпадают." >&2
    exit 1
fi
if [[ -z "$USERNAME" || -z "$USER_PASSWORD" ]]; then
    echo "Ошибка: имя пользователя и пароль не могут быть пустыми." >&2
    exit 1
fi

# ---------- 2. Проверка среды ----------
if [[ $EUID -ne 0 ]]; then
    echo "Скрипт должен быть запущен от root." >&2
    exit 1
fi
if ! ping -c 1 archlinux.org &>/dev/null; then
    echo "Ошибка: нет подключения к интернету. Подключитесь и повторите." >&2
    exit 1
fi

echo "=== ВНИМАНИЕ ==="
echo "Скрипт изменит разметку диска /dev/nvme0n1."
echo "Будет создан новый раздел для Arch Linux в свободном месте."
echo "Существующий ESP (Windows) будет использован для systemd-boot."
echo "Убедитесь, что у вас есть резервная копия данных Windows."
read -rp "Продолжить? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Отменено."
    exit 0
fi

# ---------- 3. Разметка диска ----------
DISK="/dev/nvme0n1"
# Проверяем наличие свободного места (упрощённо: создаём раздел в конце)
# В реальном сценарии лучше использовать sgdisk/parted для точного определения.
echo "Текущая разметка $DISK:"
lsblk -f "$DISK"

# Создаём новый раздел (предполагаем, что есть свободное место в конце)
# Используем sgdisk: создаём раздел, занимающий всё свободное место.
sgdisk --new=0:0:0 --typecode=0:8300 --change-name=0:"ArchLinux" "$DISK"

# Определяем имя нового раздела (последний раздел)
ARCH_PART=$(lsblk -ln -o NAME "$DISK" | tail -n1 | tr -d ' ')
ARCH_PART="/dev/${ARCH_PART}"
echo "Создан раздел: $ARCH_PART"

# Форматируем в btrfs (без subvolume)
mkfs.btrfs -L "ArchLinux" -f "$ARCH_PART"

# Монтируем корень
mount "$ARCH_PART" /mnt

# ---------- 4. Монтирование ESP (существующий Windows ESP) ----------
# Ищем ESP (FAT32, ef00). Обычно это /dev/nvme0n1p1.
ESP_PART=$(lsblk -ln -o NAME,PARTTYPENAME "$DISK" | awk '$2=="EFI System" {print $1; exit}')
if [[ -z "$ESP_PART" ]]; then
    echo "Ошибка: ESP не найден. Убедитесь, что Windows установлена в UEFI режиме." >&2
    exit 1
fi
ESP_PART="/dev/${ESP_PART}"
echo "Используется ESP: $ESP_PART"
mkdir -p /mnt/boot
mount "$ESP_PART" /mnt/boot

# ---------- 5. Установка базовой системы ----------
echo "Установка базовой системы..."
pacstrap /mnt base base-devel linux linux-firmware nano btrfs-progs networkmanager sudo git

# Генерация fstab
genfstab -U /mnt >> /mnt/etc/fstab

# ---------- 6. Настройка в chroot ----------
echo "Настройка системы в chroot..."
arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# Часовой пояс (при необходимости измените)
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локаль
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Имя хоста
echo "archlinux" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   archlinux.localdomain archlinux
HOSTS

# Пароль root
echo "root:${USER_PASSWORD}" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Разрешаем sudo для группы wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Включаем NetworkManager
systemctl enable NetworkManager

# ---------- 7. Русские зеркала (10 лучших) ----------
echo "Настройка русских зеркал..."
pacman -S --noconfirm reflector
reflector --country Russia --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
# Для надёжности можно также вручную добавить известные зеркала:
cat >> /etc/pacman.d/mirrorlist <<'MIRRORS'
# Россия
Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.kpfu.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.kamtv.ru/archlinux/\$repo/os/\$arch
Server = https://ru.mirrors.cicku.me/archlinux/\$repo/os/\$arch
Server = https://repository.su/archlinux/\$repo/os/\$arch
Server = https://web.sketserv.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.truenetwork.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.lebedinets.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.nw-sys.ru/archlinux/\$repo/os/\$arch
Server = https://mirror.timeweb.ru/archlinux/\$repo/os/\$arch
MIRRORS
# Перемещаем сгенерированные reflector строки ниже, чтобы приоритет был у ручных
# (опционально)

# ---------- 8. Установка minimal KDE ----------
echo "Установка minimal KDE Plasma..."
# Устанавливаем основные компоненты, избегая kde-network-meta
pacman -S --noconfirm plasma-desktop plasma-workspace sddm dolphin konsole kate

# Включаем SDDM
systemctl enable sddm

# ---------- 9. Автологин в SDDM ----------
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<AUTOLOGIN
[Autologin]
User=${USERNAME}
Session=plasma
AUTOLOGIN

# ---------- 10. systemd-boot ----------
echo "Установка systemd-boot..."
bootctl --path=/boot install

# Конфигурация загрузчика
cat > /boot/loader/loader.conf <<LOADER
default arch.conf
timeout 4
console-mode max
editor no
LOADER

# Запись Arch Linux
cat > /boot/loader/entries/arch.conf <<ARCHENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=\$(blkid -s UUID -o value "${ARCH_PART}") rw quiet
ARCHENTRY

# Запись Windows (если существует)
if [ -f /boot/EFI/Microsoft/Boot/bootmgfw.efi ]; then
    cat > /boot/loader/entries/windows.conf <<WINENTRY
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
WINENTRY
fi

# Включаем systemd-boot-update для автоматического обновления
systemctl enable systemd-boot-update.service

# ---------- 11. Установка AUR-хелпера (yay-bin) ----------
echo "Установка yay (AUR helper)..."
cd /tmp
sudo -u "${USERNAME}" git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
sudo -u "${USERNAME}" makepkg -si --noconfirm
cd /
rm -rf /tmp/yay-bin

# ---------- 12. Добавление репозиториев ----------
echo "Добавление archlinuxcn, chaotic-aur, blackarch..."

# archlinuxcn
cat >> /etc/pacman.conf <<'ARCHCN'
[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
ARCHCN
pacman -S --noconfirm archlinuxcn-keyring

# chaotic-aur
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
cat >> /etc/pacman.conf <<'CHAOTIC'
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
CHAOTIC

# blackarch
curl -O https://blackarch.org/strap.sh
chmod +x strap.sh
./strap.sh
rm strap.sh

# Обновляем базы
pacman -Sy

# ---------- 13. Пустой bash-скрипт в автозагрузку ----------
echo "Создание пустого скрипта в автозагрузке..."
USER_HOME="/home/${USERNAME}"
EMPTY_SCRIPT="${USER_HOME}/empty-autostart.sh"
touch "${EMPTY_SCRIPT}"
chmod +x "${EMPTY_SCRIPT}"
chown "${USERNAME}:${USERNAME}" "${EMPTY_SCRIPT}"

# Создаём .desktop файл для автозагрузки KDE
AUTOSTART_DIR="${USER_HOME}/.config/autostart"
mkdir -p "${AUTOSTART_DIR}"
cat > "${AUTOSTART_DIR}/empty-script.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Empty Script
Exec=${EMPTY_SCRIPT}
X-GNOME-Autostart-enabled=true
DESKTOP
chown -R "${USERNAME}:${USERNAME}" "${AUTOSTART_DIR}"

# ---------- 14. Завершение ----------
echo "Установка завершена. Перезагрузка через 10 секунд..."
sleep 10
reboot
EOF
