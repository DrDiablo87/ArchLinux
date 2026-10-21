#!/usr/bin/env bash
#
# Скрипт установки Arch Linux в dual boot с Windows
# Раздел: /dev/nvme0n1p5 (будет отформатирован)
# Файловая система: Btrfs (без subvolume)
# Загрузчик: systemd-boot
# Окружение: Minimal KDE, автологин, nano, AUR, русские зеркала,
#            репозитории archlinuxcn, chaotic-aur, blackarch.
#

set -euo pipefail

# --- 1. Запрос данных пользователя ---
echo "=== Настройка пользователя ==="
read -rp "Введите имя нового пользователя: " USERNAME
read -rsp "Введите пароль для пользователя ${USERNAME}: " USER_PASSWORD
echo
read -rsp "Повторите пароль: " USER_PASSWORD_CONFIRM
echo

if [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; then
    echo "Ошибка: пароли не совпадают." >&2
    exit 1
fi

if [[ -z "$USERNAME" || -z "$USER_PASSWORD" ]]; then
    echo "Ошибка: имя пользователя и пароль не могут быть пустыми." >&2
    exit 1
fi

# --- 2. Проверка прав и раздела ---
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен с правами root." >&2
   exit 1
fi

TARGET_PART="/dev/nvme0n1p5"
if [[ ! -b "$TARGET_PART" ]]; then
    echo "Ошибка: блочное устройство ${TARGET_PART} не найдено." >&2
    exit 1
fi

echo "ВНИМАНИЕ: Раздел ${TARGET_PART} будет полностью отформатирован."
read -rp "Продолжить? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Установка отменена."
    exit 1
fi

# --- 3. Настройка зеркал (Россия) ---
echo "=== Настройка зеркал pacman ==="
# Используем reflector для выбора 10 самых быстрых российских HTTPS-зеркал
if command -v reflector &>/dev/null; then
    reflector --country Russia --protocol https --latest 10 --sort rate --save /etc/pacman.d/mirrorlist
else
    # Если reflector недоступен, используем статический список популярных зеркал
    cat > /etc/pacman.d/mirrorlist <<'EOF'
Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch
Server = https://mirror.kpfu.ru/archlinux/$repo/os/$arch
Server = https://mirror.timeweb.ru/archlinux/$repo/os/$arch
Server = https://mirror.kamtv.ru/archlinux/$repo/os/$arch
Server = https://ru.mirrors.cicku.me/archlinux/$repo/os/$arch
Server = https://mirror.lebedinets.ru/archlinux/$repo/os/$arch
Server = https://mirror.nw-sys.ru/archlinux/$repo/os/$arch
Server = https://mirror.ps.kz/archlinux/$repo/os/$arch
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF
fi
echo "Зеркала настроены."

# --- 4. Форматирование и монтирование ---
echo "=== Форматирование ${TARGET_PART} в Btrfs ==="
mkfs.btrfs -f -L ArchLinux "$TARGET_PART"

echo "=== Монтирование корня ==="
mount "$TARGET_PART" /mnt

# --- 5. Установка базовой системы ---
echo "=== Установка базовых пакетов (pacstrap) ==="
pacstrap -K /mnt \
    base base-devel linux linux-firmware \
    btrfs-progs nano sudo networkmanager \
    plasma-desktop sddm konsole dolphin \
    pipewire pipewire-pulse wireplumber \
    firefox git

# --- 6. Генерация fstab ---
echo "=== Генерация fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

# --- 7. Настройка системы в chroot ---
echo "=== Вход в chroot для настройки ==="
arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -euo pipefail

# Часовой пояс (при необходимости измените)
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локаль
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

# Имя хоста
echo "ArchLinux" > /etc/hostname

# Пароль root
echo "root:${USER_PASSWORD}" | chpasswd

# Создание пользователя
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# Разрешение sudo для группы wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# Включение multilib (требуется для некоторых пакетов BlackArch)
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf

# --- 8. Добавление сторонних репозиториев ---

# archlinuxcn
echo '
[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
' >> /etc/pacman.conf
pacman -Sy --noconfirm archlinuxcn-keyring

# Chaotic-AUR
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo '
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
' >> /etc/pacman.conf

# BlackArch
pacman-key --recv-keys 7533BAFE69A25079
pacman-key --lsign-key 7533BAFE69A25079
echo '
[blackarch]
Server = https://mirrors.bfsu.edu.cn/blackarch/\$repo/os/\$arch
' >> /etc/pacman.conf
pacman -Sy --noconfirm blackarch-keyring

# Обновление системы с новыми репозиториями
pacman -Syu --noconfirm

# --- 9. Установка systemd-boot ---
echo "=== Установка systemd-boot ==="
bootctl --esp-path=/boot install
cat > /boot/loader/loader.conf <<'LOADER'
default arch.conf
timeout 4
editor 0
LOADER

# Получаем PARTUUID корневого раздела
ROOT_PARTUUID=\$(blkid -s PARTUUID -o value "${TARGET_PART}")
cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=\${ROOT_PARTUUID} rw rootfstype=btrfs
ENTRY

# --- 10. Настройка автологина SDDM ---
echo "=== Настройка автологина ==="
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<SDDM
[Autologin]
User=${USERNAME}
Session=plasma
SDDM

# --- 11. Включение служб ---
systemctl enable NetworkManager
systemctl enable sddm

# --- 12. Установка AUR helper (yay) ---
echo "=== Установка yay (AUR helper) ==="
sudo -u "${USERNAME}" bash -c '
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay
'

# --- 13. Создание пустого скрипта в автозагрузке ---
echo "=== Создание пустого скрипта автозагрузки ==="
# Создаем пустой скрипт в /usr/local/bin
touch /usr/local/bin/startup-empty-script.sh
chmod +x /usr/local/bin/startup-empty-script.sh

# Создаем systemd-юнит для его запуска при старте
cat > /etc/systemd/system/startup-empty-script.service <<'SERVICE'
[Unit]
Description=Empty Startup Script
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/startup-empty-script.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable startup-empty-script.service

CHROOT_EOF

# --- 14. Завершение установки и перезагрузка ---
echo "=== Установка завершена! ==="
echo "Размонтирование разделов..."
umount -R /mnt

echo "Система будет перезагружена через 10 секунд."
echo "Не забудьте извлечь установочный носитель."
sleep 10
reboot
