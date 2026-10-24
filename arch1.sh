#!/bin/bash
# Скрипт установки Arch Linux в dual boot с Windows (NVMe, btrfs, systemd-boot, linux-zen)
# Запускать из Live-среды Arch Linux под root

set -e  # Прерывать выполнение при любой ошибке

# --- Цветной вывод ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# --- 1. Запрос данных пользователя ---
info "=== Настройка пользователя и паролей ==="
read -r -p "Введите имя создаваемого пользователя: " USERNAME
while [[ -z "$USERNAME" ]]; do
    warn "Имя пользователя не может быть пустым."
    read -r -p "Введите имя создаваемого пользователя: " USERNAME
done

read -r -s -p "Введите пароль для пользователя $USERNAME: " USER_PASS
echo
read -r -s -p "Повторите пароль: " USER_PASS_CONFIRM
echo
while [[ "$USER_PASS" != "$USER_PASS_CONFIRM" ]]; do
    warn "Пароли не совпадают."
    read -r -s -p "Введите пароль для пользователя $USERNAME: " USER_PASS
    echo
    read -r -s -p "Повторите пароль: " USER_PASS_CONFIRM
    echo
done

read -r -s -p "Введите пароль для суперпользователя (root): " ROOT_PASS
echo
read -r -s -p "Повторите пароль root: " ROOT_PASS_CONFIRM
echo
while [[ "$ROOT_PASS" != "$ROOT_PASS_CONFIRM" ]]; do
    warn "Пароли не совпадают."
    read -r -s -p "Введите пароль для root: " ROOT_PASS
    echo
    read -r -s -p "Повторите пароль root: " ROOT_PASS_CONFIRM
    echo
done
info "Данные пользователя сохранены."

# --- 2. Определение NVMe диска и EFI раздела ---
info "=== Поиск NVMe диска и EFI раздела Windows ==="
# Ищем NVMe диски (тип disk, имя содержит nvme)
mapfile -t NVME_DISKS < <(lsblk -dno NAME,TYPE | awk '$2=="disk" && $1 ~ /^nvme/ {print $1}')

if [[ ${#NVME_DISKS[@]} -eq 0 ]]; then
    error "NVMe диски не найдены. Скрипт предназначен для NVMe."
    exit 1
elif [[ ${#NVME_DISKS[@]} -eq 1 ]]; then
    NVME_DISK="/dev/${NVME_DISKS[0]}"
    info "Найден NVMe диск: $NVME_DISK"
else
    warn "Найдено несколько NVMe дисков:"
    for d in "${NVME_DISKS[@]}"; do echo "  /dev/$d"; done
    read -r -p "Введите имя NVMe диска для установки (например, nvme0n1): " NVME_DISK_INPUT
    NVME_DISK="/dev/$NVME_DISK_INPUT"
fi

# Проверяем, что диск существует
if [[ ! -b "$NVME_DISK" ]]; then
    error "Устройство $NVME_DISK не существует."
    exit 1
fi

# Ищем EFI System Partition (ESP) на этом диске
ESP_PART=$(lsblk -no NAME,PARTTYPE "$NVME_DISK" | awk '$2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1}' | head -n1)
if [[ -z "$ESP_PART" ]]; then
    error "EFI System Partition не найден на $NVME_DISK. Убедитесь, что Windows установлена в UEFI режиме."
    exit 1
fi
ESP_DEV="/dev/$ESP_PART"
info "Найден EFI раздел: $ESP_DEV"

# Вывод информации о диске для подтверждения
info "Текущая разметка диска $NVME_DISK:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT "$NVME_DISK"

warn "Скрипт создаст новый раздел btrfs на всём оставшемся свободном месте диска $NVME_DISK."
warn "Windows и существующие разделы затронуты НЕ будут."
read -r -p "Продолжить? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    info "Установка отменена."
    exit 0
fi

# --- 3. Создание нового раздела и форматирование в btrfs ---
info "=== Создание нового раздела btrfs ==="
# Создаём раздел, занимающий всё свободное место (sgdisk -n 0:0:0)
sgdisk -n 0:0:0 "$NVME_DISK"
partprobe "$NVME_DISK"
sleep 2

# Определяем имя нового раздела (последний раздел на диске)
NEW_PART=$(lsblk -no NAME "$NVME_DISK" | tail -n1)
ROOT_DEV="/dev/$NEW_PART"
info "Создан раздел: $ROOT_DEV"

# Форматируем в btrfs (без subvolume)
mkfs.btrfs -f "$ROOT_DEV"

# --- 4. Монтирование ---
info "=== Монтирование разделов ==="
mount "$ROOT_DEV" /mnt
mkdir -p /mnt/boot
mount "$ESP_DEV" /mnt/boot
info "Корень смонтирован в /mnt, EFI раздел — в /mnt/boot"

# --- 5. Установка базовых пакетов ---
info "=== Установка базовых пакетов (base, linux-zen, KDE minimal, etc.) ==="
pacstrap -K /mnt \
    base base-devel linux-zen linux-zen-headers \
    btrfs-progs nano networkmanager sudo \
    plasma-desktop sddm konsole dolphin \
    pipewire pipewire-pulse wireplumber \
    reflector git

# --- 6. Генерация fstab ---
info "=== Генерация /etc/fstab ==="
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

# --- 7. Настройка системы в chroot ---
info "=== Настройка системы (chroot) ==="
arch-chroot /mnt /bin/bash <<EOF
set -e

# Часовой пояс (Москва)
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

# Локали
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Имя хоста
echo "archlinux" > /etc/hostname

# Пароль root
echo "root:${ROOT_PASS}" | chpasswd

# Создание пользователя и настройка sudo
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${USER_PASS}" | chpasswd
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Включение NetworkManager
systemctl enable NetworkManager

# --- Зеркала: 10 лучших российских ---
reflector --country Russia --latest 10 --sort rate --save /etc/pacman.d/mirrorlist

# --- Добавление archlinuxcn ---
cat >> /etc/pacman.conf <<'PACMAN_CN'

[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
PACMAN_CN

# --- Добавление Chaotic-AUR ---
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
                'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

cat >> /etc/pacman.conf <<'PACMAN_CHAOTIC'

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
PACMAN_CHAOTIC

# Обновление баз данных и установка keyring'ов
pacman -Sy --noconfirm archlinuxcn-keyring

# --- Установка systemd-boot ---
bootctl --path=/boot install

# Настройка loader.conf
cat > /boot/loader/loader.conf <<'LOADER'
default arch-zen.conf
timeout 3
editor 0
LOADER

# Получение UUID корневого раздела
ROOT_UUID=\$(blkid -s UUID -o value ${ROOT_DEV})

# Создание entry для linux-zen
cat > /boot/loader/entries/arch-zen.conf <<ENTRY
title   Arch Linux (linux-zen)
linux   /vmlinuz-linux-zen
initrd  /initramfs-linux-zen.img
options root=UUID=\${ROOT_UUID} rw
ENTRY

# --- Установка yay (AUR helper) от имени пользователя ---
su - "${USERNAME}" -c "
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
"

# --- Настройка autologin в SDDM ---
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/autologin.conf <<SDDM
[Autologin]
User=${USERNAME}
Session=plasma
SDDM

systemctl enable sddm

# --- Создание пустого bash-скрипта и сервиса автозагрузки ---
cat > /usr/local/bin/empty_script.sh <<'EMPTY'
#!/bin/bash
exit 0
EMPTY
chmod +x /usr/local/bin/empty_script.sh

cat > /etc/systemd/system/empty_script.service <<'SERVICE'
[Unit]
Description=Empty script autostart

[Service]
Type=oneshot
ExecStart=/usr/local/bin/empty_script.sh

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable empty_script.service

# --- Завершение ---
echo "Настройка завершена."
EOF

# --- 8. Размонтирование и перезагрузка ---
info "=== Размонтирование и перезагрузка ==="
umount -R /mnt
info "Установка завершена. Система будет перезагружена."
reboot
