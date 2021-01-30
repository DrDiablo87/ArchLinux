#!/bin/bash

loadkeys ru
setfont cyr-sun16

#Синхронизация системных часов
timedatectl set-ntp true

echo -e '\033[32m'
read -p "Введите имя компьютера: " hostname
read -p "Введите имя пользователя: " username
read -p "Введите пароль root " rootpass
read -p "Введите пароль user " userpass
export hostname username rootpass userpass

echo -e '\033[32m' &&

#dd if=/dev/zero of=/dev/sda bs=1024 count=50
wipefs -a /dev/sda

#Ваша разметка диска
echo -e '\e[31m' ; lsblk -f

#Форматирование дисков
mkfs.btrfs -L "Arch" -n 64k /dev/sda

#Монтирование дисков
mount -o compress=lzo /dev/sda /mnt
cd /mnt
btrfs subvolume create @
cd /
umount /mnt
mount -t btrfs -o noatime,nodatasum,compress=lzo,ssd,max_inline=0,subvol=@ /dev/sda /mnt


#Выбор зеркал для загрузки
echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

echo -e '
\e[31m==================================================================================== Установка основных пакетов ==================================\e[0m
'
echo -e '\033[32m'
pacstrap /mnt base nano linux #linux-firmware base-devel

echo -e '
\e[31m==================================================================================== Настройка системы ===========================================\e[0m
'
echo -e '\033[32m'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL git.io/www1.sh)"
systemctl reboot
