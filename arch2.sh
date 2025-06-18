 #!/bin/bash

echo -e '\033[32m'

#Прописываем имя компьютера
echo $hostname > /etc/hostname
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

setfont cyr-sun16
#Добавляем русскую локаль системы
echo "en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8" > /etc/locale.gen 

#Обновим текущую локаль системы
locale-gen

#Указываем язык системы
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf

echo 'MODULES="" 
BINARIES="" 
FILES="" 
HOOKS="base udev autodetect modconf block filesystems keyboard keymap"' > /etc/mkinitcpio.conf

rm /boot/initramfs-linux-zen-fallback.img /boot/initramfs-linux-fallback.img
echo 'ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=default
default_image="/boot/initramfs-linux.img"' > /etc/mkinitcpio.d/linux.preset
echo 'ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-zen"
PRESETS=default
default_image="/boot/initramfs-linux-zen.img"' > /etc/mkinitcpio.d/linux-zen.preset

echo -e '

\e[31m==================================================================================== Устанавливаем загрузчик =====================================\e[0m
'
echo -e '\033[32m'
pacman -S efibootmgr git wget reflector amd-ucode --noconfirm  
#reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm
#echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
#Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть

bootctl install
echo 'default Arch
timeout 1
editor 0' > /boot/loader/loader.conf

if [ -e /dev/sda5 ]; then
echo 'title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=/dev/sda5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
else 
echo 'title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=/dev/nvme0n1p2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
echo 'title Arch Linux Zen
linux /vmlinuz-linux-zen
initrd /amd-ucode.img
initrd /initramfs-linux-zen.img
options root=/dev/nvme0n1p2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinuxZen.conf
fi

#Добавляем пользователя
useradd -m -g users -G audio,games,video,storage,wheel -s /bin/bash $username

echo -e '

\e[31m==================================================================================== Создаем root пароль =========================================\e[0m
'
echo -e '\033[32m'

echo -e "$rootpass\n$rootpass" | passwd
echo -e "$userpass\n$userpass" | passwd $username

echo -e '\033[32m'
#Устанавливаем SUDO
echo 'root ALL=(ALL) ALL
'$username' ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
'$username' ALL = NOPASSWD: /bin/systemctl
Defaults env_reset, timestamp_timeout=30' > /etc/sudoers

git clone https://github.com/DrDiablo87/ArchLinux.git /home/$username/ArchLinux

#Настройка Pacman.conf
echo '[options]
#
CacheDir = /home/'$username'/Package/
HoldPkg = pacman glibc
#
Architecture = auto
#
Color
#
CheckSpace
#
IgnorePkg =
#
SigLevel = Never
LocalFileSigLevel = Never
ParallelDownloads = 10
#
[core]
Include = /etc/pacman.d/mirrorlist
#
[extra]
Include = /etc/pacman.d/mirrorlist
#
[multilib]
Include = /etc/pacman.d/mirrorlist
#
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
SigLevel = Never
#' > /etc/pacman.conf
curl -O https://blackarch.org/strap.sh
sh ./strap.sh
rm ./strap.sh
echo 'SigLevel = Never' >> /etc/pacman.conf

#curl -s "https://blackarch.org/blackarch-mirrorlist" -o "/etc/pacman.d/blackarch-mirrorlist"
#cp /home/$username/ArchLinux/Package/blackarch-mirrorlist /etc/pacman.d/blackarch-mirrorlist
#pacman -Syyu --noconfirm

sed -i 's!#PKGDEST=/home/packages!PKGDEST=~/Package!' /etc/makepkg.conf
echo 'MAKEFLAGS="-j'$(nproc)'"
BILDDIR=/temp/makepkg' >> /etc/makepkg.conf
                                             
echo '127.0.1.1   '$hostname'.localdomain   '$hostname'
#127.0.0.1 localhost
#::1       localhost
127.0.0.1 admulti.com
127.0.0.1 pt.upzona.net
127.0.0.1 gag.admulti.com
127.0.0.1 go.video.admulti.com' >> /etc/hosts

echo 'include "/usr/share/nano/*.nanorc"' > /etc/nanorc                      #Раскраска nano

echo -e '



