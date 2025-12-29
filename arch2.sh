 #!/bin/bash

echo DrDiablo > /etc/hostname
ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
setfont cyr-sun16
echo "en_US.UTF-8 UTF-8
ru_RU.UTF-8 UTF-8" > /etc/locale.gen 
locale-gen
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
pacman -S efibootmgr git wget reflector amd-ucode --noconfirm  
reflector --country Russia --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
pacman -Syu --noconfirm
bootctl install
echo 'default Arch
timeout 1
editor 0' > /boot/loader/loader.conf

if [ -e /dev/nvme0n1p5 ]; then
echo 'title Arch Linux
linux /vmlinuz-linux
initrd /amd-ucode.img
initrd /initramfs-linux.img
options root=/dev/nvme0n1p5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
echo 'title Arch Linux Zen
linux /vmlinuz-linux-zen
initrd /amd-ucode.img
initrd /initramfs-linux-zen.img
options root=/dev/nvme0n1p5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinuxZen.conf
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

useradd -m -g users -G audio,games,video,storage,wheel -s /bin/bash Diablo

echo -e "$rootpass\n$rootpass" | passwd
echo -e "$userpass\n$userpass" | passwd Diablo

echo 'root ALL=(ALL) ALL
Diablo ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
Diablo ALL = NOPASSWD: /bin/systemctl
Defaults env_reset, timestamp_timeout=30' > /etc/sudoers
git clone https://github.com/DrDiablo87/ArchLinux.git /home/Diablo/ArchLinux
systemctl enable --now systemd-networkd.service
systemctl enable --now systemd-resolved.service
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'  --noconfirm
pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'  --noconfirm
echo '[options]
#
CacheDir = /home/Diablo/Package/
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
sed -i 's!#PKGDEST=/home/packages!PKGDEST=~/Package!' /etc/makepkg.conf
echo 'MAKEFLAGS="-j'$(nproc)'"
BILDDIR=/temp/makepkg' >> /etc/makepkg.conf                                         
echo '127.0.1.1   DrDiablo.localdomain   DrDiablo
#127.0.0.1 localhost
#::1       localhost
127.0.0.1 admulti.com
127.0.0.1 pt.upzona.net
127.0.0.1 gag.admulti.com
127.0.0.1 go.video.admulti.com' >> /etc/hosts

echo 'include "/usr/share/nano/*.nanorc"' > /etc/nanorc                 
pacman -S --needed lib32-mesa mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader libva-mesa-driver lib32-libva-mesa-driver xorg-drivers xorg-xinit --noconfirm
pacman -S yay plasma-pa plasma-nm plasma-desktop dolphin kate konsole kde-gtk-config  --noconfirm
pacman -S ark p7zip unzip unrar zip unarchiver qbittorrent gwenview kompare kde-gtk-config plasma-sdk encfs cryfs kscreen sddm-kcm kinfocenter wireshark-qt spectacle ktouch kwave krita kdenlive kleopatra krfb krdc freerdp kdegraphics-thumbnailers kdesdk-thumbnailers ffmpegthumbs kdesdk-thumbnailers breeze-gtk kfind cmake extra-cmake-modules systemdgenie plasma-systemmonitor bluedevil bluez-utils --noconfirm
pacman -S firefox-i18n-ru firefox-ublock-origin filelight ntfs-3g gufw mtr exfat-utils cronie gnome-disk-utility f2fs-tools udftools net-tools libvirt linux-headers qt5-translations kdeplasma-addons networkmanager-openvpn openresolv kcalc tree openssh bridge-utils partitionmanager --noconfirm
pacman -S steam ttf-liberation ttf-dejavu --noconfirm
mkdir -p /home/Diablo/.config /home/Diablo/.local/share/konsole
pacman -S zsh-theme-powerlevel10k awesome-terminal-fonts zsh-syntax-highlighting zsh-autosuggestions neofetch lsd bat fd --noconfirm
usermod -s /usr/bin/zsh Diablo
usermod -s /usr/bin/zsh root
cp /home/Diablo/ArchLinux/Package/.zshrc /home/Diablo/.zshrc
cp /home/Diablo/ArchLinux/Package/zshrc /etc/zsh/zshrc
mkdir -p /home/Diablo/.config/neofetch
cp /home/Diablo/ArchLinux/Package/config.conf /home/Diablo/.config/neofetch/config.conf
cp /home/Diablo/ArchLinux/Package/konsolerc /home/Diablo/.config/konsolerc
mkdir -p /root/.config
cp /home/Diablo/ArchLinux/Package/konsolerc /root/.config/konsolerc
cp /home/Diablo/ArchLinux/KDE/.config/yt-dlp /home/Diablo/.config/yt-dlp
mkdir /etc/sddm.conf.d                           # Автологин
echo '[Theme]
CursorTheme=breeze_cursors' > /etc/sddm.conf

echo '[Autologin]
User=Diablo
Session=plasma.desktop
Numlock=on ' > /etc/sddm.conf.d/autologin.conf

echo '[Autologin]
Relogin=false
Session=plasma
User=Diablo

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=breeze
CursorTheme=breeze_cursors

[Users]
MaximumUid=60000
MinimumUid=1000 ' > /etc/sddm.conf.d/kde_settings.conf
chown -R Diablo:users /home/Diablo
systemctl enable systemd-timesyncd.service
timedatectl set-ntp true
systemctl enable sddm.service NetworkManager.service
systemctl mask man-db.service man-db.timer 
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
systemctl mask systemd-tmpfiles-setup.service 
btrfs subvolume delete /var/lib/machines        
usermod -a -G wireshark Diablo
pacman -S amarok taglib1 gst-libav gst-plugins-bad gst-plugins-good gst-plugins-ugly --noconfirm
pacman -S mpv --noconfirm
mkdir /etc/mpv
cp /home/Diablo/ArchLinux/Package/mpv.desktop /usr/share/applications/mpv.desktop
cp /home/Diablo/ArchLinux/Package/mpv_single /usr/bin/mpv_single
chmod +x /usr/bin/mpv_single
cp /home/Diablo/ArchLinux/Package/mpv.conf /etc/mpv/mpv.conf
cp /home/Diablo/ArchLinux/Package/input.conf /etc/mpv/input.conf
pacman -S virtualbox virtualbox-guest-utils --noconfirm
cp /home/Diablo/ArchLinux/LiveWallpaper/Box.svg /usr/share/icons/breeze-dark/apps/48/Box.svg
sed -i 's/Icon=virtualbox/Icon=Box/g' /usr/share/applications/virtualbox.desktop
cp /home/Diablo/ArchLinux/Package/com.github.configurable-button.tar.xz /home/Diablo/com.github.configurable-button.tar.xz
cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze/apps/48/kleopatra.svg  
cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze-dark/apps/48/kleopatra.svg
cp /usr/share/icons/breeze/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze/preferences/32/qvkbd.svg
cp /usr/share/icons/breeze-dark/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze-dark/preferences/32/qvkbd.svg
sed -i 's/Icon=kleopatra/Icon=plasmavault/g' /usr/share/kio/servicemenus/kleopatra_decryptverifyfiles.desktop /usr/share/kio/servicemenus/kleopatra_signencryptfiles.desktop /usr/share/kio/servicemenus/kleopatra_signencryptfolders.desktop
sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf
sed -i 's/use-ipv6=yes/use-ipv6=no/g' /etc/avahi/avahi-daemon.conf
cp /home/Diablo/ArchLinux/Package/systemdgenie.mo /usr/share/locale/ru/LC_MESSAGES/systemdgenie.mo
cp /home/Diablo/ArchLinux/Package/config.conf /home/Diablo/.config/neofetch/config.conf
cp /home/Diablo/ArchLinux/LiveWallpaper/Airgeddon.svg /usr/share/icons/breeze-dark/apps/48/Airgeddon.svg
cp /home/Diablo/ArchLinux/LiveWallpaper/Airgeddon.svg /usr/share/icons/breeze/apps/48/Airgeddon.svg
cp /home/Diablo/ArchLinux/LiveWallpaper/Metasploit.svg /usr/share/icons/breeze-dark/apps/48/Metasploit.svg
cp /home/Diablo/ArchLinux/LiveWallpaper/Metasploit.svg /usr/share/icons/breeze/apps/48/Metasploit.svg
cp /home/Diablo/ArchLinux/KDE/.face.icon  /usr/share/plasma/avatars/Kurchatov.png
cp /home/Diablo/ArchLinux/KDE/.local/share/applications/Archlinux-icon-crystal-64.png /usr/share/icons/breeze-dark/apps/48/Archlinux-icon-crystal-64.png
mkdir -p /home/Diablo/.config/autostart
echo '[Desktop Entry]
Exec=konsole -e sh /home/Diablo/ArchLinux/arch3.sh
Icon=application-x-shellscript
Name=arch3.sh
Type=Application
X-KDE-AutostartScript=true' > /home/Diablo/.config/autostart/arch3.sh.desktop
chmod +x /home/Diablo/ArchLinux/arch3.sh
chmod +x /home/Diablo/.config/autostart/arch3.sh.desktop
echo "
tmpfs      /home/Diablo/.cache tmpfs rw 0 0
tmpfs						/var/log	tmpfs	defaults,noatime 0 0
tmpfs						/var/run	tmpfs	defaults,noatime 0 0
tmpfs						/var/lock	tmpfs	defaults,noatime 0 0 " >> /etc/fstab
rm -R /home/Diablo/.bash_logout /home/Diablo/.bash_profile /home/Diablo/.bashrc /home/Diablo/Package /var/cache/pacman/pkg
chown -R Diablo:users /home/Diablo

