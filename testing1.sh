#!/bin/bash

echo -e '\033[32m'

#Прописываем имя компьютера
echo $hostname > /etc/hostname
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

#Добавляем русскую локаль системы
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen 

#Обновим текущую локаль системы
locale-gen

#Указываем язык системы
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo 'KEYMAP=ru
FONT=cyr-sun16' > /etc/vconsole.conf

echo 'MODULES="" 
BINARIES="" 
FILES="" 
HOOKS="base udev autodetect modconf block filesystems keyboard keymap"' > /etc/mkinitcpio.conf
mkinitcpio -p linux

echo -e '
\e[31m==================================================================================== Устанавливаем загрузчик =====================================\e[0m
'
echo -e '\033[32m'
pacman -S grub --noconfirm 

#chattr -i /boot/grub/i386-pc/core.img
#grub-install --target=i386-pc --grub-setup=/bin/true /dev/sda
#grub-mkconfig -o /boot/grub/grub.cfg
#chattr +i /boot/grub/i386-pc/core.img

grub-install  --grub-setup=/bin/true /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
#grub-install --boot-directory=/mnt/@/boot /dev/sda

#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть +++++++++++++++++++++++++++++++++++++++++++++++++

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

#Настройка Pacman.conf
echo '[options]
#
CacheDir = /home/'$username'/Package/
HoldPkg = pacman glibc
#
Architecture = auto
#
#Color
#
CheckSpace
#
IgnorePkg =
#
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional
#
[core]
Include = /etc/pacman.d/mirrorlist
#
[extra]
Include = /etc/pacman.d/mirrorlist
#
[community]
Include = /etc/pacman.d/mirrorlist
#
[multilib]
Include = /etc/pacman.d/mirrorlist
#' > /etc/pacman.conf

sed -i 's!#PKGDEST=/home/packages!PKGDEST=~/Package!' /etc/makepkg.conf

pacman -Syyu --noconfirm
                                                  
echo '127.0.1.1   '$hostname'.localdomain   '$hostname'
127.0.0.1 admulti.com
127.0.0.1 pt.upzona.net
127.0.0.1 gag.admulti.com
127.0.0.1 go.video.admulti.com' >> /etc/hosts

echo 'include "/usr/share/nano/*.nanorc"' > /etc/nanorc                      #Раскраска nano


echo -e '
\e[31m===================================================================================== Устанавливем Blackarch =====================================\e[0m
'


echo -e '
\e[31m==================================================================================== Ставим KDE ==================================================\e[0m
'
echo -e '\033[32m'
sed -i 's/#MAKEFLAGS="-j'$(nproc)'"/MAKEFLAGS="-j'$(nproc)'"/g' /etc/makepkg.conf
pacman -S xorg-drivers xorg-xinit mesa-vdpau lib32-mesa plasma-desktop sddm dolphin kdialog dolphin-plugins kate konsole plasma-nm plasma-pa --noconfirm
systemctl enable sddm.service NetworkManager.service

#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть +++++++++++++++++++++++++++++++++++++++++++++++++

pacman -S yay --noconfirm
#pacman -S ark p7zip unzip unrar zip unarchiver reflector kdesdk-thumbnailers ffmpegthumbs raw-thumbnailer breeze-gtk kfind cmake extra-cmake-modules systemdgenie --noconfirm
pacman -S mc htop ncdu --noconfirm
#pacman -S edk2-ovmf virt-manager qemu ffmpeg youtube-dl mediainfo-gui --noconfirm  && systemctl start libvirtd.service && systemctl enable libvirtd.service
#sed -i 's|image/\*\,||' /usr/share/kservices5/ServiceMenus/mediainfo-gui.desktop
#pacman -S firefox-i18n-ru qtox bleachbit krita filelight ntfs-3g gufw exfat-utils cronie gnome-disk-utility f2fs-tools udftools steam net-tools  libvirt linux-headers kid3 qtcreator qt5-translations kdeplasma-addons networkmanager-openvpn openresolv kalzium kcalc tree gbrainy kmplot kmag wireshark-qt openssh --noconfirm
#pacman -S steam-native-runtime --noconfirm
#Ставим шрифты
#pacman -S ttf-liberation ttf-dejavu xterm --noconfirm 


echo "
tmpfs						/var/log	tmpfs	defaults,noatime 0 0
tmpfs						/var/run	tmpfs	defaults,noatime 0 0
tmpfs						/var/lock	tmpfs	defaults,noatime 0 0 " >> /etc/fstab
