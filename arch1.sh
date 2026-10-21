#!/usr/bin/env bash
# =============================================================================
# Arch Linux dual-boot installer (root) with systemd-boot, minimal KDE,
# Btrfs (no subvolumes), auto-login, AUR, Russian mirrors, extra repos.
# =============================================================================
set -euo pipefail

# ---------- 1. Запрос учётных данных -----------------------------------------
read -rp "Введите имя нового пользователя: " USERNAME
while [[ -z "$USERNAME" ]]; do
    read -rp "Имя пользователя не может быть пустым. Повторите: " USERNAME
done

read -rsp "Введите пароль для $USERNAME: " USER_PASSWORD
echo
read -rsp "Повторите пароль: " USER_PASSWORD_CONFIRM
echo
if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
    echo "Пароли не совпадают." >&2
    exit 1
fi

read -rsp "Введите пароль для root: " ROOT_PASSWORD
echo
read -rsp "Повторите пароль root: " ROOT_PASSWORD_CONFIRM
echo
if [[ "$ROOT_PASSWORD" != "$ROOT_PASSWORD_CONFIRM" ]]; then
    echo "Пароли root не совпадают." >&2
    exit 1
fi

# ---------- 2. Определение диска и ESP ---------------------------------------
DISK="/dev/nvme0n1"
if [[ ! -b "$DISK" ]]; then
    echo "Диск $DISK не найден. Укажите правильное устройство в переменной DISK." >&2
    exit 1
fi

# Поиск EFI System Partition (тип EF00 / ef00)
ESP=""
while read -r part; do
    if [[ -n "$part" ]]; then
        ESP="$part"
        break
    fi
done < <(lsblk -lnpo NAME,PARTTYPE "$DISK" | awk '$2=="ef00" || $2=="EF00" {print $1}')

if [[ -z "$ESP" ]]; then
    echo "Не удалось автоматически найти EFI System Partition на $DISK." >&2
    echo "Найдите её вручную (lsblk -f) и задайте переменную ESP." >&2
    exit 1
fi
echo "Используется ESP: $ESP"

# ---------- 3. Разметка свободного места -------------------------------------
# Создаём новый раздел, занимающий всё свободное пространство после последнего.
# Предполагается, что свободное место находится в конце диска.
LAST_PART_NUM=$(lsblk -lnpo NAME "$DISK" | grep -E "${DISK}p?[0-9]+$" | sed -E 's/.*p?([0-9]+)$/\1/' | sort -n | tail -1)
NEW_PART_NUM=$((LAST_PART_NUM + 1))
NEW_PART="${DISK}p${NEW_PART_NUM}"

echo "Создаётся новый раздел $NEW_PART (займёт всё свободное место)..."
parted -s "$DISK" mkpart primary btrfs "$(parted -s "$DISK" unit s print free | awk '/Free Space/ {print $3}' | tail -1 | sed 's/s//')" 100%

# Даём ядру перечитать таблицу разделов
partprobe "$DISK"
sleep 2

# ---------- 4. Форматирование и монтирование ---------------------------------
echo "Форматирование $NEW_PART в Btrfs (без сабволюмов)..."
mkfs.btrfs -L ArchLinux -f "$NEW_PART"

echo "Монтирование корня в /mnt..."
mount "$NEW_PART" /mnt

echo "Монтирование ESP в /mnt/efi..."
mkdir -p /mnt/efi
mount "$ESP" /mnt/efi

# ---------- 5. Установка базовой системы -------------------------------------
echo "Установка базовых пакетов..."
pacstrap /mnt base base-devel linux linux-firmware btrfs-progs nano \
    networkmanager sddm plasma-desktop \
    sudo git reflector

# ---------- 6. Генерация fstab ----------------------------------------------
genfstab -U /mnt >> /mnt/etc/fstab

# ---------- 7. Настройка системы в chroot ------------------------------------
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

# Часовой пояс (измените при необходимости)
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локаль
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Имя хоста
echo "archlinux" > /etc/hostname

# Пароль root
echo "root:${ROOT_PASSWORD}" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Разрешение sudo для группы wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/10-wheel

# Редактор по умолчанию — nano
echo 'EDITOR=nano' >> /etc/environment
echo 'VISUAL=nano' >> /etc/environment

# ---------- 8. Русские зеркала (10 лучших) -----------------------------------
reflector --country Russia --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# ---------- 9. Добавление репозиториев ---------------------------------------
# archlinuxcn
cat >> /etc/pacman.conf <<'EOF'

[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
EOF

# chaotic-aur
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
                 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
cat >> /etc/pacman.conf <<'EOF'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

# blackarch
cat >> /etc/pacman.conf <<'EOF'

[blackarch]
Server = https://www.blackarch.org/blackarch/\$arch
EOF

# Обновление баз и импорт ключей для сторонних репозиториев
pacman -Sy --noconfirm
pacman -S --noconfirm archlinuxcn-keyring
pacman -S --noconfirm blackarch-keyring

# ---------- 10. Автологин SDDM -----------------------------------------------
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<EOF
[Autologin]
User=${USERNAME}
Session=plasma
EOF

# Включение SDDM
systemctl enable sddm

# ---------- 11. Установка AUR-хелпера (yay) ----------------------------------
# yay доступен в archlinuxcn, поэтому собирать из AUR не нужно.
pacman -S --noconfirm yay

# ---------- 12. Пустой скрипт в автозагрузке ---------------------------------
# Создаём пустой скрипт и systemd-сервис для его запуска при загрузке.
touch /usr/local/bin/empty-autostart.sh
chmod +x /usr/local/bin/empty-autostart.sh

cat > /etc/systemd/system/empty-autostart.service <<'EOF'
[Unit]
Description=Empty autostart script
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/empty-autostart.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl enable empty-autostart.service

# ---------- 13. Установка systemd-boot ----------------------------------------
# ESP уже смонтирован в /efi (в chroot это /efi)
bootctl --esp-path=/efi install

# Запись загрузки для Arch Linux
ROOT_UUID=$(blkid -s UUID -o value "${NEW_PART}")
cat > /efi/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=${ROOT_UUID} rw quiet
EOF

# Включение обнаружения Windows (если установлен пакет)
# systemd-boot автоматически добавляет Windows Boot Manager, если он есть в ESP.
# Дополнительная ручная запись не требуется.

# ---------- 14. Завершение ---------------------------------------------------
echo "Установка завершена. Перезагрузка через 10 секунд..."
sleep 10
reboot
CHROOT

# На случай, если reboot внутри chroot не сработает
echo "Если перезагрузка не началась, выполните reboot вручную."
