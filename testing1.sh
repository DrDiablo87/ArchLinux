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

pacman -S grub --noconfirm
grub-install /dev/sda

#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть
#=========================================================================================================================================================================================================
#bootctl install
#echo 'default Arch
#timeout 1
#editor 0' > /boot/loader/loader.conf

#if [ -e /dev/sda5 ]; then
#echo 'title Arch Linux
#linux /vmlinuz-linux
#initrd /amd-ucode.img
#initrd /initramfs-linux.img
#options root=/dev/sda5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
#echo 'title Arch Linux Zen
#linux /vmlinuz-linux-zen
#initrd /amd-ucode.img
#initrd /initramfs-linux-zen.img
#options root=/dev/sda5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinuxZen.conf
#else 
#echo 'title Arch Linux
#linux /vmlinuz-linux
#initrd /amd-ucode.img
#initrd /initramfs-linux.img
#options root=/dev/sda2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
#echo 'title Arch Linux Zen
#linux /vmlinuz-linux-zen
#initrd /amd-ucode.img
#initrd /initramfs-linux-zen.img
#options root=/dev/sda2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinuxZen.conf
#fi
#=========================================================================================================================================================================================================
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

pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'  --noconfirm
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'  --noconfirm

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
#
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
SigLevel = Never
#' > /etc/pacman.conf
curl -O https://blackarch.org/strap.sh
sed -i 's/pacman -S --noconfirm --needed blackarch-officials/ /g' ./strap.sh
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

\e[31m==================================================================================== Ставим KDE ==================================================\e[0m
'
echo -e '\033[32m'
#sed -i 's/#MAKEFLAGS="-j'$(nproc)'"/MAKEFLAGS="-j'$(nproc)'"/g' /etc/makepkg.conf
#NVIDIA
#pacman -S --needed nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
#AMD
pacman -S --needed lib32-mesa mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau xorg-drivers xorg-xinit --noconfirm
#INTEL
#pacman -S --needed lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader --noconfirm
#pacman -S nvidia-settings nvidia nvidia-settings xorg-server-devel opencl-nvidia nvidia && wget https://ru.download.nvidia.com/XFree86/Linux-x86_64/390.141/NVIDIA-Linux-x86_64-390.141.run
####pacman -S plasma-workspace xorg sddm sddm-kcm networkmanager --noconfirm
pacman -S yay plasma-pa plasma-nm plasma-desktop dolphin kate konsole kde-gtk-config  --noconfirm
#pacman -Rns blackarch-officials --noconfirm
#pacman -S bettercap ettercap bully pixiewps hashcat tcpdump mdk4 reaver hcxtools john onionshare metasploit --noconfirm

#systemctl enable sddm.service
systemctl enable NetworkManager.service

pacman -S ark p7zip unzip unrar zip unarchiver qbittorrent gwenview kompare kde-gtk-config plasma-sdk encfs cryfs kscreen sddm-kcm kinfocenter wireshark-qt spectacle ktouch kwave krita kdenlive kleopatra krfb krdc freerdp kdegraphics-thumbnailers kdesdk-thumbnailers ffmpegthumbs kdesdk-thumbnailers breeze-gtk kfind cmake extra-cmake-modules systemdgenie plasma-systemmonitor bluedevil bluez-utils --noconfirm
pacman -S firefox-i18n-ru firefox-ublock-origin filelight ntfs-3g gufw mtr exfat-utils cronie gnome-disk-utility f2fs-tools udftools net-tools libvirt linux-headers qt5-translations kdeplasma-addons networkmanager-openvpn openresolv kcalc tree openssh bridge-utils --noconfirm
pacman -S steam ttf-liberation ttf-dejavu --noconfirm
#pacman -R partitionmanager --noconfirm

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
mkdir -p /home/$username/.config/neofetch
cp /home/$username/ArchLinux/Package/config.conf /home/$username/.config/neofetch/config.conf
cp /home/$username/ArchLinux/Package/konsolerc /home/$username/.config/konsolerc
mkdir -p /root/.config
cp /home/$username/ArchLinux/Package/konsolerc /root/.config/konsolerc
cp /home/$username/ArchLinux/KDE/.config/yt-dlp /home/$username/.config/yt-dlp

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

chown -R $username:users /home/$username

#pacman -S torsocks tor i2pd torctl --noconfirm
#cp /home/$username/ArchLinux/Package/i2pd.conf /etc/i2pd/i2pd.conf
#mv /etc/systemd/system/torctl-autostart.service /etc/systemd/system/Tor.service
#mv /usr/lib/systemd/system/i2pd.service /usr/lib/systemd/system/I2pd.service
#mv /usr/lib/systemd/system/libvirtd.service /usr/lib/systemd/system/VManager.service
#mv /usr/lib/systemd/system/sshd.service /usr/lib/systemd/system/SSH.service

systemctl enable systemd-timesyncd.service
timedatectl set-ntp true
systemctl enable sddm.service NetworkManager.service
systemctl mask man-db.service man-db.timer 
#systemctl disable avahi-daemon
#systemctl mask avahi-daemon
#systemctl mask avahi-daemon.service
#systemctl mask avahi-daemon.socket
systemctl mask ModemManager.service
systemctl mask lvm2-monitor.socket
systemctl mask lvm2-monitor.service
systemctl mask lvm2-lvmpolld.socket
systemctl mask lvm2-lvmpolld.service
systemctl mask lvm2-lvmetad.socket
systemctl mask lvm2-lvmetad.service
systemctl mask lvm2-activation.service
systemctl mask lvm2-activation-early.service
systemctl mask systemd-journald-audit.socket
systemctl mask systemd-journald-dev-log.socket
systemctl enable fstrim.timer
systemctl enable bluetooth.service
systemctl mask systemd-tmpfiles-setup.service    # предотвращение создания проблемного снапшота
btrfs subvolume delete /var/lib/machines         # удаление проблемного снапшота
usermod -a -G wireshark $username

#===========================================================================================================================================================================================================

echo -e '

\e[31m==================================================================================== Установка и настройка MPV ===================================\e[0m
'
echo -e '\033[32m'

pacman -S amarok taglib1 gst-libav gst-plugins-bad gst-plugins-good gst-plugins-ugly --noconfirm

pacman -S mpv --noconfirm
cp /home/$username/ArchLinux/Package/mpv.desktop /usr/share/applications/mpv.desktop
cp /home/$username/ArchLinux/Package/mpv_single /usr/bin/mpv_single
chmod +x /usr/bin/mpv_single
cp /home/$username/ArchLinux/Package/mpv.conf /etc/mpv/mpv.conf
cp /home/$username/ArchLinux/Package/input.conf /etc/mpv/input.conf

echo -e '

\e[31m==================================================================================== Установка и настройка Live Wallpaper ========================\e[0m
'
echo -e '\033[32m'

#cp /home/$username/.config/LiveWallpaper/archlinux-logo-dark.png /usr/share/sddm/themes/breeze/archlinux-logo-dark.png
pacman -S virtualbox virtualbox-guest-utils --noconfirm
cp /home/$username/ArchLinux/LiveWallpaper/Box.svg /usr/share/icons/breeze-dark/apps/48/Box.svg
#cp /home/$username/ArchLinux/LiveWallpaper/Box.svg /usr/share/icons/breeze/apps/48/Box.svg
sed -i 's/Icon=virtualbox/Icon=Box/g' /usr/share/applications/virtualbox.desktop
#SWAP

#truncate -s 0 /swapfile
#chattr +C /swapfile
#fallocate -l 512M /swapfile
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo /swapfile none swap sw 0 0 | sudo tee -a /etc/fstab
#echo 'vm.swappiness=10' > /etc/sysctl.d/99-sysctl.conf
cp /home/$username/ArchLinux/Package/com.github.configurable-button.tar.xz /home/$username/com.github.configurable-button.tar.xz

cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze/apps/48/kleopatra.svg  
cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze-dark/apps/48/kleopatra.svg
cp /usr/share/icons/breeze/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze/preferences/32/qvkbd.svg
cp /usr/share/icons/breeze-dark/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze-dark/preferences/32/qvkbd.svg
sed -i 's/Icon=kleopatra/Icon=plasmavault/g' /usr/share/kio/servicemenus/kleopatra_decryptverifyfiles.desktop /usr/share/kio/servicemenus/kleopatra_signencryptfiles.desktop /usr/share/kio/servicemenus/kleopatra_signencryptfolders.desktop
sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf
sed -i 's/use-ipv6=yes/use-ipv6=no/g' /etc/avahi/avahi-daemon.conf
cp /home/$username/ArchLinux/Package/systemdgenie.mo /usr/share/locale/ru/LC_MESSAGES/systemdgenie.mo
cp /home/$username/ArchLinux/Package/config.conf /home/$username/.config/neofetch/config.conf

cp /home/$username/ArchLinux/LiveWallpaper/Airgeddon.svg /usr/share/icons/breeze-dark/apps/48/Airgeddon.svg
cp /home/$username/ArchLinux/LiveWallpaper/Airgeddon.svg /usr/share/icons/breeze/apps/48/Airgeddon.svg
cp /home/$username/ArchLinux/LiveWallpaper/Metasploit.svg /usr/share/icons/breeze-dark/apps/48/Metasploit.svg
cp /home/$username/ArchLinux/LiveWallpaper/Metasploit.svg /usr/share/icons/breeze/apps/48/Metasploit.svg
cp /home/$username/ArchLinux/KDE/.face.icon  /usr/share/plasma/avatars/Kurchatov.png
cp /home/$username/ArchLinux/KDE/.local/share/applications/Archlinux-icon-crystal-64.png /usr/share/icons/breeze-dark/apps/48/Archlinux-icon-crystal-64.png

mkdir -p /home/$username/.config/autostart

echo '[Desktop Entry]
Exec=konsole -e sh /home/'$username'/ArchLinux/arch3.sh
Icon=application-x-shellscript
Name=arch3.sh
Type=Application
X-KDE-AutostartScript=true' > /home/$username/.config/autostart/arch3.sh.desktop
chmod +x /home/$username/ArchLinux/arch3.sh
chmod +x /home/$username/.config/autostart/arch3.sh.desktop


echo "
tmpfs      /home/'$username'/.cache tmpfs rw 0 0
tmpfs						/var/log	tmpfs	defaults,noatime 0 0
tmpfs						/var/run	tmpfs	defaults,noatime 0 0
tmpfs						/var/lock	tmpfs	defaults,noatime 0 0 " >> /etc/fstab

rm -R /home/$username/.bash_logout /home/$username/.bash_profile /home/$username/.bashrc /home/$username/Package /var/cache/pacman/pkg
chown -R $username:users /home/$username

#cp -Rf /home/$username/ArchLinux/KDE/.config /home/$username/.config
#cp -Rf /home/$username/ArchLinux/KDE/. /root
