#!/bin/bash

echo -e '\033[32m'

#Прописываем имя компьютера
echo $hostname > /etc/hostname
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc

loadkeys ru
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
reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
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
options root=/dev/sda2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
echo 'title Arch Linux Zen
linux /vmlinuz-linux-zen
initrd /amd-ucode.img
initrd /initramfs-linux-zen.img
options root=/dev/sda2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinuxZen.conf
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
[community]
Include = /etc/pacman.d/mirrorlist
#
[multilib]
Include = /etc/pacman.d/mirrorlist
#
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
SigLevel = Never
#
[blackarch]
Server = http://mirror.yandex.ru/mirrors/blackarch/$repo/os/$arch
Server = https://mirror.cyberbits.eu/blackarch/$repo/os/$arch
Server = https://mirror.tillo.ch/ftp/blackarch/$repo/os/$arch
Server = https://www.blackarch.org/blackarch/$repo/os/$arch
Server = https://blackarch.unixpeople.org/$repo/os/$arch
Server = https://www.mirrorservice.org/sites/blackarch.org/blackarch/$repo/os/$arch
Server = https://ftp.halifax.rwth-aachen.de/blackarch/$repo/os/$arch
Server = https://mirror.undisclose.de/blackarch/$repo/os/$arch
SigLevel = Never' > /etc/pacman.conf

#curl -s "https://blackarch.org/blackarch-mirrorlist" -o "/etc/pacman.d/blackarch-mirrorlist"
#cp /home/$username/ArchLinux/Package/blackarch-mirrorlist /etc/pacman.d/blackarch-mirrorlist
pacman -Syyu --noconfirm

sed -i 's!#PKGDEST=/home/packages!PKGDEST=~/Package!' /etc/makepkg.conf
                                                 
echo '127.0.1.1   '$hostname'.localdomain   '$hostname'
#127.0.0.1 localhost
#::1       localhost
127.0.0.1 admulti.com
127.0.0.1 pt.upzona.net
127.0.0.1 gag.admulti.com
127.0.0.1 go.video.admulti.com' >> /etc/hosts

echo 'include "/usr/share/nano/*.nanorc"' > /etc/nanorc                      #Раскраска nano

echo -e '

\e[31m==================================================================================== Ставим KDE ==================================================\e[0m
'
echo -e '\033[32m'
sed -i 's/#MAKEFLAGS="-j'$(nproc)'"/MAKEFLAGS="-j'$(nproc)'"/g' /etc/makepkg.conf
#NVIDIA
#pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
#AMD
pacman -S --needed lib32-mesa mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau --noconfirm
#INTEL
#pacman -S --needed lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm

pacman -S xorg-drivers nvidia xorg-xinit mesa-vdpau lib32-mesa --noconfirm
#pacman -S nvidia-settings nvidia-settings xorg-server-devel opencl-nvidia nvidia && wget https://ru.download.nvidia.com/XFree86/Linux-x86_64/390.141/NVIDIA-Linux-x86_64-390.141.run
####pacman -S plasma-workspace xorg sddm sddm-kcm networkmanager --noconfirm
pacman -S plasma plasma-meta plasma-pa plasma-desktop kde-system-meta kde-utilities-meta kio-extras kwalletmanager konsole  kwalletmanager --noconfirm
pacman -S yay --noconfirm
systemctl enable sddm.service
systemctl enable NetworkManager.service

pacman -S ark p7zip unzip unrar zip unarchiver qbittorrent okular okteta gwenview kompare kde-gtk-config arc-gtk-theme plasma-vault plasma-sdk encfs cryfs kscreen sddm-kcm kwalletmanager kinfocenter spectacle ktouch kwave kdenlive ksystemlog kleopatra krfb krdc freerdp kdegraphics-thumbnailers kdesdk-thumbnailers ffmpegthumbs kdesdk-thumbnailers breeze-gtk kfind cmake extra-cmake-modules systemdgenie --noconfirm
sed -i 's|image/\*\,||' /usr/share/kservices5/ServiceMenus/mediainfo-gui.desktop
pacman -S firefox-i18n-ru firefox-ublock-origin jami-qt bleachbit krita filelight ntfs-3g gufw mtr exfat-utils cronie gnome-disk-utility f2fs-tools udftools steam net-tools libvirt linux-headers kid3 qtcreator qt5-translations kdeplasma-addons networkmanager-openvpn openresolv kalzium kcalc tree gbrainy kalgebra kmag wireshark-qt openssh nmap bridge-utils --noconfirm
pacman -S steam-native-runtime ttf-liberation ttf-dejavu xterm --noconfirm

echo -e '

\e[31m==================================================================================== Ставим и настрайваем ZSH ====================================\e[0m
'
echo -e '\033[32m'

mkdir -p /home/$username/.config /home/$username/.local/share/konsole
pacman -S zsh-theme-powerlevel10k awesome-terminal-fonts zsh-syntax-highlighting zsh-autosuggestions neofetch lsd bat fd --noconfirm
usermod -s /usr/bin/zsh $username
usermod -s /usr/bin/zsh root
cp /home/$username/ArchLinux/Package/.zshrc /home/$username/.zshrc
cp /home/$username/ArchLinux/Package/zshrc /etc/zsh/zshrc
mkdir /home/$username/.config/neofetch
cp /home/$username/ArchLinux/Package/config.conf /home/$username/.config/neofetch/config.conf
cp /home/$username/ArchLinux/Package/ArcDark.colorscheme /home/$username/.local/share/konsole/ArcDark.colorscheme
cp /home/$username/ArchLinux/Package/'Profile 1.profile' /home/$username/.local/share/konsole/'Profile 1.profile'
cp /home/$username/ArchLinux/Package/konsolerc /home/$username/.config/konsolerc
cp /home/$username/ArchLinux/Package/ArcDark.colorscheme /root/share/konsole/ArcDark.colorscheme
cp /home/$username/ArchLinux/Package/'Profile 1.profile' /root/share/konsole/'Profile 1.profile'
cp /home/$username/ArchLinux/Package/konsolerc /root/.config/konsolerc
chown -R $username:users /home/$username

echo -e '

#==============================================================================================================================================================
'
#Настраиваем тему
mkdir /etc/sddm.conf.d                           # Автологин
echo '[Theme]
CursorTheme=breeze_cursors' > /etc/sddm.conf

echo '[Autologin]
User='$username'
Session=plasma.desktop
Numlock=on ' > /etc/sddm.conf.d/autologin.conf

echo '[Autologin]
Relogin=false
Session=plasma
User='$username'

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze
CursorTheme=breeze_cursors

[Users]
MaximumUid=60000
MinimumUid=1000 ' > /etc/sddm.conf.d/kde_settings.conf

echo '[Layout]
DisplayNames=,
LayoutList=us,ru
Options=grp:alt_shift_toggle
ResetOldOptions=true
Use=true
VariantList=,' > /home/$username/.config/kxkbrc

chown -R $username:users /home/$username

pacman -S torsocks tor i2pd torctl --noconfirm
cp /home/$username/ArchLinux/Package/i2pd.conf /etc/i2pd/i2pd.conf
mv /etc/systemd/system/torctl-autostart.service /etc/systemd/system/Tor.service
mv /usr/lib/systemd/system/i2pd.service /usr/lib/systemd/system/I2pd.service
mv /usr/lib/systemd/system/libvirtd.service /usr/lib/systemd/system/VManager.service
mv /usr/lib/systemd/system/sshd.service /usr/lib/systemd/system/SSH.service

timedatectl set-ntp yes
systemctl enable sddm.service NetworkManager.service
systemctl mask man-db.service man-db.timer 
systemctl disable avahi-daemon
systemctl mask avahi-daemon
systemctl mask avahi-daemon.service
systemctl mask avahi-daemon.socket
systemctl mask ModemManager.service
systemctl mask lvm2-monitor.socket
systemctl mask lvm2-monitor.service
systemctl mask lvm2-lvmpolld.socket
systemctl mask lvm2-lvmpolld.service
systemctl mask lvm2-lvmetad.socket
systemctl mask lvm2-lvmetad.service
systemctl mask lvm2-activation.service
systemctl mask lvm2-activation-early.service
systemctl mask systemd-journald.socket
#systemctl mask systemd-journald.service
systemctl mask systemd-journald-audit.socket
systemctl mask systemd-journald-dev-log.socket
systemctl enable fstrim.service
systemctl enable fstrim.timer
systemctl mask systemd-tmpfiles-setup.service    # предотвращение создания проблемного снапшота
btrfs subvolume delete /var/lib/machines         # удаление проблемного снапшота
usermod -a -G wireshark $username











