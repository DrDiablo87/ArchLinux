#!/usr/bin/env bash
#
# Скрипт установки Arch Linux в dual boot с Windows.
# Автоматически создаёт раздел в самом большом свободном блоке на /dev/nvme0n1,
# форматирует в Btrfs, настраивает systemd-boot, minimal KDE, автологин,
# AUR, репозитории archlinuxcn / chaotic-aur / blackarch, русские зеркала.
#

set -euo pipefail

# ============ 1. Запрос данных пользователя ============
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

# ============ 2. Проверки окружения ============
if [[ $EUID -ne 0 ]]; then
    echo "Этот скрипт должен быть запущен с правами root." >&2
    exit 1
fi

if [[ ! -d /sys/firmware/efi ]]; then
    echo "Ошибка: система загружена не в режиме UEFI." >&2
    echo "systemd-boot требует UEFI. Перезагрузитесь с UEFI." >&2
    exit 1
fi

DISK="/dev/nvme0n1"
if [[ ! -b "$DISK" ]]; then
    echo "Ошибка: диск $DISK не найден." >&2
    exit 1
fi

# Поиск существующего EFI System Partition (общий с Windows)
ESP_PART=$(lsblk -ln -o NAME,PARTTYPE "$DISK" | \
    awk '$2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print "/dev/"$1}' | head -1)
if [[ -z "$ESP_PART" ]]; then
    echo "Ошибка: EFI System Partition не найден на $DISK." >&2
    exit 1
fi
echo "Найден EFI-раздел: $ESP_PART"

# ============ 3. Настройка зеркал (Россия) ============
echo "=== Настройка зеркал pacman ==="
if command -v reflector &>/dev/null; then
    reflector --country Russia --protocol https --latest 10 --sort rate \
              --save /etc/pacman.d/mirrorlist
else
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

# ============ 4. Автоматическая разметка свободного места ============
echo "=== Таблица разделов ДО ==="
sgdisk -p "$DISK"

# Проверка наличия свободного места (минимум ~20 GiB)
FREE_SECTORS=$(sgdisk -F "$DISK" 2>/dev/null || true)
if [[ -z "$FREE_SECTORS" ]]; then
    echo "Ошибка: на диске нет свободного (неразмеченного) места." >&2
    exit 1
fi
FREE_BYTES=$(( FREE_SECTORS * 512 ))
FREE_GIB=$(( FREE_BYTES / 1024 / 1024 / 1024 ))
echo "Свободно неразмеченного места: примерно ${FREE_GIB} GiB"
if (( FREE_GIB < 20 )); then
    echo "Ошибка: недостаточно свободного места (нужно минимум 20 GiB)." >&2
    exit 1
fi

# Следующий номер раздела
LAST_NUM=$(lsblk -ln -o NAME "$DISK" | grep -oP "^${DISK##*/}p\K[0-9]+" | sort -n | tail -1)
NEW_NUM=$(( LAST_NUM + 1 ))
TARGET_PART="${DISK}p${NEW_NUM}"

echo "Будет создан раздел ${TARGET_PART} (тип Linux filesystem) во всём свободном месте."
read -rp "Продолжить разметку и установку? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Установка отменена."
    exit 1
fi

# Создаём новый раздел в самом большом свободном блоке
sgdisk --largest-new=${NEW_NUM} --typecode=${NEW_NUM}:8300 "$DISK"
partprobe "$DISK"
sleep 1

if [[ ! -b "$TARGET_PART" ]]; then
    echo "Ошибка: не удалось создать раздел $TARGET_PART." >&2
    exit 1
fi
echo "Создан раздел: $TARGET_PART"

echo "=== Таблица разделов ПОСЛЕ ==="
sgdisk -p "$DISK"

# ============ 5. Форматирование и монтирование ============
echo "=== Форматирование $TARGET_PART в Btrfs ==="
mkfs.btrfs -f -L ArchLinux "$TARGET_PART"

echo "=== Монтирование корня ==="
mount "$TARGET_PART" /mnt

echo "=== Монтирование EFI-раздела в /boot ==="
mkdir -p /mnt/boot
# Если Windows оставил ESP в «грязном» состоянии из-за гибернации —
# монтирование read-write может не сработать, тогда будет ошибка.
mount "$ESP_PART" /mnt/boot

# ============ 6. Установка базовой системы ============
echo "=== Установка базовых пакетов (pacstrap) ==="
pacstrap /mnt \
    base base-devel linux linux-firmware \
    btrfs-progs nano sudo networkmanager \
    plasma-desktop sddm konsole dolphin \
    pipewire pipewire-pulse wireplumber \
    firefox git

# ============ 7. Генерация fstab ============
echo "=== Генерация fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab

# ============ 8. Настройка в chroot ============
echo "=== Вход в chroot для настройки ==="
arch-chroot /mnt /bin/bash <<CHROOT_EOF
set -euo pipefail

# Часовой пояс
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локали
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

# Имя хоста
echo "ArchLinux" > /etc/hostname

# Пароль root
echo "root:${USER_PASSWORD}" | chpasswd

# Пользователь
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# sudo для wheel
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

# multilib (нужен для части пакетов BlackArch)
sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf

# --- Сторонние репозитории ---

# archlinuxcn
printf '\n[archlinuxcn]\nServer = https://repo.archlinuxcn.org/\\\$arch\n' >> /etc/pacman.conf
pacman -Sy --noconfirm archlinuxcn-keyring

# Chaotic-AUR
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> /etc/pacman.conf

# BlackArch
pacman-key --recv-keys 7533BAFE69A25079
pacman-key --lsign-key 7533BAFE69A25079
printf '\n[blackarch]\nServer = https://mirrors.bfsu.edu.cn/blackarch/\\\$repo/os/\\\$arch\n' >> /etc/pacman.conf
pacman -Sy --noconfirm blackarch-keyring

# Обновление с учётом новых репозиториев
pacman -Syu --noconfirm

# --- systemd-boot ---
echo "=== Установка systemd-boot ==="
bootctl --esp-path=/boot install

cat > /boot/loader/loader.conf <<'LOADER'
default arch.conf
timeout 4
editor 0
LOADER

ROOT_PARTUUID=\$(blkid -s PARTUUID -o value "${TARGET_PART}")
cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=PARTUUID=\${ROOT_PARTUUID} rw rootfstype=btrfs
ENTRY

# --- Автологин SDDM ---
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<SDDM
[Autologin]
User=${USERNAME}
Session=plasma
SDDM

# --- Службы ---
systemctl enable NetworkManager
systemctl enable sddm

# --- yay (AUR helper) ---
echo "=== Установка yay (AUR helper) ==="
sudo -u "${USERNAME}" bash -c '
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay
'

# --- Пустой скрипт в автозагрузку ---
touch /usr/local/bin/startup-empty-script.sh
chmod +x /usr/local/bin/startup-empty-script.sh

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

# ============ 9. Завершение ============
echo "=== Установка завершена! ==="
echo "Размонтирование разделов..."
umount -R /mnt

echo "Система будет перезагружена через 10 секунд."
echo "Не забудьте извлечь установочный носитель."
sleep 10
reboot
