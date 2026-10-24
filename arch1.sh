#!/usr/bin/env bash
# =============================================================================
# Установка Arch Linux в dual boot с Windows
# - Btrfs-корень (без subvolume)
# - systemd-boot (без GRUB)
# - Минимальный KDE + автологин SDDM
# - 10 лучших русских зеркал, AUR, archlinuxcn, chaotic-aur, blackarch
# - Пустой bash-скрипт в автозагрузке
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
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Ошибка: имя пользователя должно начинаться с буквы/подчёркивания и содержать только a-z, 0-9, _, -." >&2
    exit 1
fi
unset USER_PASSWORD_CONFIRM

# ---------- 2. Проверка среды ----------
if [[ $EUID -ne 0 ]]; then
    echo "Скрипт должен быть запущен от root." >&2
    exit 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
    echo "Ошибка: система загружена в Legacy/BIOS режиме. systemd-boot требует UEFI." >&2
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
read -rp "Продолжить? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Отменено."
    exit 0
fi

# ---------- 3. Разметка диска ----------
DISK="/dev/nvme0n1"

echo "Текущая разметка $DISK:"
lsblk -f "$DISK"

# Создаём новый раздел в свободном месте с GPT-меткой ArchLinux
sgdisk --new=0:0:0 --typecode=0:8300 --change-name=0:"ArchLinux" "$DISK"

# Обновляем таблицу разделов в ядре
if command -v partprobe >/dev/null 2>&1; then
    partprobe "$DISK"
fi
udevadm settle

# Ищем раздел по GPT-метке
ARCH_PART=$(lsblk -ln -o NAME,PARTLABEL "$DISK" \
    | awk '$2=="ArchLinux" {print "/dev/"$1; exit}')

if [[ -z "$ARCH_PART" ]]; then
    echo "ОШИБКА: раздел с меткой ArchLinux не найден. Диагностика:"
    lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,PARTTYPE "$DISK"
    exit 1
fi

echo "Создан раздел: $ARCH_PART"
mkfs.btrfs -L "ArchLinux" -f "$ARCH_PART"
mount "$ARCH_PART" /mnt

# UUID корня для systemd-boot
ARCH_UUID=$(blkid -s UUID -o value "$ARCH_PART")
if [[ -z "$ARCH_UUID" ]]; then
    echo "ОШИБКА: не удалось получить UUID раздела $ARCH_PART." >&2
    exit 1
fi
echo "UUID корня: $ARCH_UUID"

# ---------- 4. Поиск и монтирование ESP ----------
echo "Поиск ESP..."

ESP_GUID="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"
ESP_PART=""

# Способ 1: по GUID типа раздела (без пробелов в значениях)
ESP_PART=$(lsblk -ln -o NAME,PARTTYPE 2>/dev/null \
    | awk -v g="$ESP_GUID" 'tolower($2)==g {print "/dev/"$1; exit}' || true)

# Способ 2: через -P (PARTTYPENAME="EFI System" содержит пробел, но -P парсит корректно)
if [[ -z "$ESP_PART" ]]; then
    ESP_PART=$(lsblk -P -o NAME,PARTTYPENAME 2>/dev/null \
        | grep -i 'PARTTYPENAME="EFI' \
        | head -n1 \
        | sed -E 's/^NAME="([^"]+)".*/\/dev\/\1/' || true)
fi

# Способ 3: ищем vfat-раздел с каталогом /EFI (последняя линия обороны)
if [[ -z "$ESP_PART" ]]; then
    echo "GUID/тип не сработали, ищу vfat-раздел с /EFI..."
    while read -r part; do
        [[ -z "$part" ]] && continue
        fstype=$(blkid -s TYPE -o value "$part" 2>/dev/null || true)
        [[ "$fstype" != "vfat" ]] && continue
        mkdir -p /tmp/esp_check
        if mount -o ro "$part" /tmp/esp_check 2>/dev/null; then
            if [[ -d /tmp/esp_check/EFI ]]; then
                ESP_PART="$part"
                umount /tmp/esp_check
                rmdir /tmp/esp_check 2>/dev/null || true
                break
            fi
            umount /tmp/esp_check
        fi
    done < <(lsblk -ln -o NAME,TYPE 2>/dev/null | awk '$2=="part"{print "/dev/"$1}')
    rmdir /tmp/esp_check 2>/dev/null || true
fi

if [[ -z "$ESP_PART" ]]; then
    echo "ОШИБКА: ESP не найден. Диагностика:"
    lsblk -f
    echo "---"
    blkid
    echo "---"
    for d in $(lsblk -dn -o NAME 2>/dev/null); do
        echo "=== /dev/$d ==="
        lsblk -o NAME,SIZE,FSTYPE,PARTTYPE,PARTLABEL "/dev/$d" 2>/dev/null || true
    done
    exit 1
fi

echo "Используется ESP: $ESP_PART"
mkdir -p /mnt/boot
mount "$ESP_PART" /mnt/boot

# ---------- 5. Установка базовой системы ----------
echo "Установка базовой системы..."
pacstrap /mnt base base-devel linux linux-firmware nano btrfs-progs \
    networkmanager sudo git curl reflector

genfstab -U /mnt >> /mnt/etc/fstab

# ---------- 6. Подготовка переменных для chroot ----------
# Безопасно экранируем переменные, чтобы спецсимволы в пароле не сломали chroot-скрипт
{
    printf 'USERNAME=%q\n'      "$USERNAME"
    printf 'USER_PASSWORD=%q\n' "$USER_PASSWORD"
    printf 'ARCH_UUID=%q\n'     "$ARCH_UUID"
} > /mnt/install-vars.sh

# ---------- 7. Пост-установочный скрипт ----------
cat > /mnt/post-install.sh <<'POSTINSTALL'
#!/bin/bash
set -euo pipefail
source /install-vars.sh

# Часовой пояс
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локали
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

# Пароль root (такой же, как у пользователя — при необходимости измените)
echo "root:${USER_PASSWORD}" | chpasswd

# Пользователь
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASSWORD}" | chpasswd

# sudo для группы wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

# NetworkManager
systemctl enable NetworkManager

# ---------- Русские зеркала ----------
echo "Настройка русских зеркал..."
reflector --country Russia --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# Резервные русские зеркала (на случай недоступности основных)
cat >> /etc/pacman.d/mirrorlist <<'MIRRORS'
# Россия (резерв)
Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch
Server = https://mirror.kpfu.ru/archlinux/$repo/os/$arch
Server = https://mirror.kamtv.ru/archlinux/$repo/os/$arch
Server = https://ru.mirrors.cicku.me/archlinux/$repo/os/$arch
Server = https://repository.su/archlinux/$repo/os/$arch
Server = https://web.sketserv.ru/archlinux/$repo/os/$arch
Server = https://mirror.truenetwork.ru/archlinux/$repo/os/$arch
Server = https://mirror.lebedinets.ru/archlinux/$repo/os/$arch
Server = https://mirror.nw-sys.ru/archlinux/$repo/os/$arch
Server = https://mirror.timeweb.ru/archlinux/$repo/os/$arch
MIRRORS

pacman -Syy --noconfirm

# ---------- Минимальный KDE ----------
echo "Установка минимального KDE Plasma..."
pacman -S --noconfirm plasma-desktop plasma-workspace sddm dolphin konsole kate

systemctl enable sddm

# Автологин в SDDM
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<AUTOLOGIN
[Autologin]
User=${USERNAME}
Session=plasma
AUTOLOGIN

# ---------- systemd-boot ----------
echo "Установка systemd-boot..."
bootctl --esp-path=/boot install

cat > /boot/loader/loader.conf <<'LOADER'
default arch.conf
timeout 4
console-mode max
editor no
LOADER

cat > /boot/loader/entries/arch.conf <<ARCHENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=${ARCH_UUID} rw quiet
ARCHENTRY

# Запись Windows, если обнаружена
if [ -f /boot/EFI/Microsoft/Boot/bootmgfw.efi ]; then
    cat > /boot/loader/entries/windows.conf <<'WINENTRY'
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
WINENTRY
fi

systemctl enable systemd-boot-update.service 2>/dev/null || true

# ---------- AUR helper (yay-bin) ----------
echo "Установка yay (AUR helper)..."
cd /tmp
sudo -u "${USERNAME}" git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
sudo -u "${USERNAME}" makepkg -si --noconfirm
cd /
rm -rf /tmp/yay-bin

# ---------- archlinuxcn ----------
echo "Добавление archlinuxcn..."
cat >> /etc/pacman.conf <<'ARCHCN'

[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
ARCHCN
pacman -Sy --noconfirm
pacman -S --noconfirm archlinuxcn-keyring

# ---------- chaotic-aur ----------
echo "Добавление chaotic-aur..."
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
cat >> /etc/pacman.conf <<'CHAOTIC'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
CHAOTIC
pacman -Sy --noconfirm

# ---------- blackarch ----------
echo "Добавление blackarch..."
curl -fsSO https://blackarch.org/strap.sh
chmod +x strap.sh
./strap.sh
rm -f strap.sh

pacman -Syu --noconfirm

# ---------- Пустой bash-скрипт в автозагрузку ----------
echo "Создание пустого скрипта в автозагрузке..."
USER_HOME="/home/${USERNAME}"
EMPTY_SCRIPT="${USER_HOME}/empty-autostart.sh"
cat > "${EMPTY_SCRIPT}" <<'EMPTY'
#!/bin/bash
# пустой скрипт для автозагрузки
EMPTY
chmod +x "${EMPTY_SCRIPT}"
chown "${USERNAME}:${USERNAME}" "${EMPTY_SCRIPT}"

# .desktop-файл для KDE autostart
AUTOSTART_DIR="${USER_HOME}/.config/autostart"
mkdir -p "${AUTOSTART_DIR}"
cat > "${AUTOSTART_DIR}/empty-script.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Empty Autostart Script
Exec=${EMPTY_SCRIPT}
Terminal=false
X-GNOME-Autostart-enabled=true
DESKTOP
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.config"

echo "Установка завершена."
POSTINSTALL

chmod +x /mnt/post-install.sh

# ---------- 8. Запуск в chroot ----------
echo "Настройка системы в chroot..."
arch-chroot /mnt /bin/bash /post-install.sh

# Удаляем временные файлы
rm -f /mnt/install-vars.sh /mnt/post-install.sh

# ---------- 9. Перезагрузка ----------
echo "Перезагрузка через 10 секунд..."
sleep 10
reboot
