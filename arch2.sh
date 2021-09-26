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
pacman -S efibootmgr git wget reflector intel-ucode --noconfirm  
reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
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
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=/dev/sda5 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
else 
echo 'title Arch Linux
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=/dev/sda2 rw rootflags=subvol=@ #quiet' > /boot/loader/entries/ArchLinux.conf
echo 'title Arch Linux Zen
linux /vmlinuz-linux-zen
initrd /intel-ucode.img
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
#
[archlinuxcn]
Server = https://repo.archlinuxcn.org/$arch
SigLevel = Never
#
[blackarch]
Server = https://www.blackarch.org/blackarch/$repo/os/$arch
#Include = /etc/pacman.d/blackarch-mirrorlist
SigLevel = Never' > /etc/pacman.conf

#curl -s "https://blackarch.org/blackarch-mirrorlist" -o "/etc/pacman.d/blackarch-mirrorlist"
cp /home/$username/ArchLinux/Package/blackarch-mirrorlist /etc/pacman.d/blackarch-mirrorlist
pacman -Syyu --noconfirm
sed -i 's!#PKGDEST=/home/packages!PKGDEST=~/Package!' /etc/makepkg.conf
                                                 
echo '127.0.1.1   '$hostname'.localdomain   '$hostname'
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
pacman -S xorg-drivers nvidia xorg-xinit mesa-vdpau lib32-mesa plasma-desktop sddm dolphin kdialog dolphin-plugins kate konsole plasma-nm plasma-pa --noconfirm
#pacman -S nvidia-settings nvidia-settings xorg-server-devel opencl-nvidia nvidia && wget https://ru.download.nvidia.com/XFree86/Linux-x86_64/390.141/NVIDIA-Linux-x86_64-390.141.run
pacman -S yay --noconfirm
pacman -S ark p7zip unzip unrar zip unarchiver qbittorrent okular okteta gwenview qvkbd ksysguard kompare kde-gtk-config arc-gtk-theme plasma-vault plasma-sdk encfs cryfs kscreen sddm-kcm kwalletmanager plasma-wayland-session kinfocenter spectacle ktouch kwave kdenlive ksystemlog kleopatra krfb krdc freerdp kdegraphics-thumbnailers kimageformats kdesdk-thumbnailers ffmpegthumbs raw-thumbnailer breeze-gtk kfind cmake extra-cmake-modules systemdgenie --noconfirm
sed -i 's|image/\*\,||' /usr/share/kservices5/ServiceMenus/mediainfo-gui.desktop
pacman -S firefox-i18n-ru firefox-ublock-origin jami-gnome bleachbit krita filelight ntfs-3g gufw mtr exfat-utils cronie gnome-disk-utility f2fs-tools udftools steam net-tools libvirt linux-headers kid3 qtcreator qt5-translations kdeplasma-addons networkmanager-openvpn openresolv kalzium kcalc tree gbrainy kalgebra kmag wireshark-qt openssh nmap --noconfirm
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

echo -e '

\e[31m==================================================================================== Настраиваем службы ==========================================\e[0m
'
echo -e '\033[32m'
pacman -S networkmanager torsocks tor i2pd torctl --noconfirm
cp /home/$username/ArchLinux/Package/i2pd.conf /etc/i2pd/i2pd.conf
mv /etc/systemd/system/torctl-autostart.service /etc/systemd/system/Tor.service
mv /usr/lib/systemd/system/i2pd.service /usr/lib/systemd/system/I2pd.service
mv /usr/lib/systemd/system/libvirtd.service /usr/lib/systemd/system/VManager.service
mv /usr/lib/systemd/system/sshd.service /usr/lib/systemd/system/SSH.service

#Подключаем автозагрузку менеджера входа и интернет
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

#Настраиваем тему
mkdir /etc/sddm.conf.d                           # Автологин
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
MinimumUid=1000 ' > /etc/sddm.conf


echo -e '

\e[31m==================================================================================== Установка и настройка MPV ===================================\e[0m
'
echo -e '\033[32m'
pacman -U /home/$username/ArchLinux/Package/arc-kde-git-220180614.r11.g04873ca-1-any.pkg.tar.xz --noconfirm
#cp /home/$username/ArchLinux/Package/amarok.mo /usr/share/locale/ru/LC_MESSAGES/amarok.mo
cp /home/$username/ArchLinux/Package/steghide-kdialog /usr/bin/steghide-kdialog
chmod +x /usr/bin/steghide-kdialog
pacman -S amarok gst-libav gst-plugins-bad gst-plugins-good gst-plugins-ugly --noconfirm

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
pacman -S mplayer libva-vdpau-driver libva-mesa-driver libva-intel-driver libvdpau-va-gl lib32-libva-vdpau-driver lib32-mesa-vdpau lib32-libva-mesa-driver --noconfirm
pacman -U /home/$username/ArchLinux/Package/shantz-xwinwrap-bzr-20090421-3-x86_64.pkg.tar.xz  --noconfirm
mkdir /home/$username/.config/LiveWallpaper /home/$username/.config/autostart-scripts
echo "#!/bin/bash
xwinwrap -ni -fs -s -st -sp -b -nf -- mplayer -fps 25 -framedrop -wid WID -nosound "~/.config/LiveWallpaper/Galaxy.mp4" -loop 0
" > /home/$username/.config/LiveWallpaper/LiveWallpaper
chmod +x /home/$username/.config/LiveWallpaper/LiveWallpaper
touch /etc/systemd/system/Livewallpaper.service
chmod 664 /etc/systemd/system/Livewallpaper.service
echo "[Unit]
Description=LiveWallpaper

[Service]
Type=simple
User=$username
ExecStart=/bin/bash -c 'DISPLAY=:0 ~/.config/LiveWallpaper/LiveWallpaper'

[Install]
WantedBy=multi-user.target " > /etc/systemd/system/Livewallpaper.service

echo "#!/bin/bash
sudo systemctl start livewallpaper.service
" > /home/$username/.config/autostart-scripts/LiveWallpaperService
chmod +x /home/$username/.config/autostart-scripts/LiveWallpaperService

#=========================================================
wget --no-check-certificate 'https://docs.google.com/uc?export=download&id=15h4BUSE7AN9n0s_eUMd06LbkYn_9pmQM' -O /home/$username/.config/LiveWallpaper/Galaxy.mp4
echo '#brightness=-5
#vo=vdpau,
#vc=ffh264vdpau,ffmpeg12vdpau,ffodivxvdpau,ffwmv3vdpau,ffvc1vdpau,ffhevcvdpau
brightness=-10
contrast=10
saturation=10 '> /etc/mplayer/mplayer.conf
cp /home/$username/ArchLinux/LiveWallpaper/* /home/$username/.config/LiveWallpaper
cp /home/$username/.config/LiveWallpaper/screenshot.jpg /usr/share/sddm/themes/breeze/preview.png
cp /home/$username/.config/LiveWallpaper/screenshot.jpg /usr/share/sddm/themes/breeze/screenshot.jpg
cp /home/$username/.config/LiveWallpaper/archlinux-logo-dark.png /usr/share/sddm/themes/breeze/archlinux-logo-dark.png
rm -r /usr/share/wallpapers/Next/contents/

echo "[General]
background=screenshot.jpg
type=image " > /usr/share/sddm/themes/breeze/theme.conf.user

cp /home/$username/ArchLinux/Package/theme.conf /usr/share/sddm/themes/breeze/theme.conf

#Настройка Dolphin

cp /home/$username/ArchLinux/Package/Dolphin-Root.desktop /usr/share/kservices5/ServiceMenus/Dolphin-Root.desktop
cp /home/$username/ArchLinux/Package/steghide.desktop /usr/share/kservices5/ServiceMenus/steghide.desktop

pacman -S clamav --noconfirm
sed -i 's/LogFile/#LogFile/g' /etc/clamav/clamd.conf
sed -i 's/UpdateLogFile/#UpdateLogFile/g' /etc/clamav/freshclam.conf
freshclam
cp /home/$username/ArchLinux/Package/ClamAV.desktop /usr/share/kservices5/ServiceMenus/ClamAV.desktop
cp /home/$username/ArchLinux/Package/clamav.svg /usr/share/icons/hicolor/scalable/apps/clamav.svg

#SWAP

#truncate -s 0 /swapfile
#chattr +C /swapfile
#fallocate -l 512M /swapfile
#chmod 600 /swapfile
#mkswap /swapfile
#swapon /swapfile
#echo /swapfile none swap sw 0 0 | sudo tee -a /etc/fstab
#echo 'vm.swappiness=10' > /etc/sysctl.d/99-sysctl.conf

rm -r /usr/share/plasma/desktoptheme/Arc-Dark/icons
cp -r /usr/share/plasma/desktoptheme/default/icons /usr/share/plasma/desktoptheme/Arc-Dark
rm -r /usr/share/plasma/desktoptheme/Arc-Dark/widgets
cp -r /usr/share/plasma/desktoptheme/default/widgets /usr/share/plasma/desktoptheme/Arc-Dark
cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze/apps/48/kleopatra.svg  
cp /usr/share/icons/breeze/apps/48/plasmavault.svg /usr/share/icons/breeze-dark/apps/48/kleopatra.svg
cp /usr/share/icons/breeze/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze/preferences/32/qvkbd.svg
cp /usr/share/icons/breeze-dark/preferences/32/preferences-desktop-keyboard.svg /usr/share/icons/breeze-dark/preferences/32/qvkbd.svg
sed -i 's/Icon=kleopatra/Icon=plasmavault/g' /usr/share/kservices5/kleopatra_decryptverifyfiles.desktop /usr/share/kservices5/kleopatra_decryptverifyfolders.desktop /usr/share/kservices5/kleopatra_signencryptfiles.desktop /usr/share/kservices5/kleopatra_signencryptfolders.desktop
sed -i 's/use-ipv4=yes/use-ipv4=no/g' /etc/avahi/avahi-daemon.conf
sed -i 's/use-ipv6=yes/use-ipv6=no/g' /etc/avahi/avahi-daemon.conf
cp /home/$username/ArchLinux/Package/systemdgenie.mo /usr/share/locale/ru/LC_MESSAGES/systemdgenie.mo
cp /home/$username/ArchLinux/arch3.sh /home/$username/1

echo "#!/bin/bash
sleep 10
konsole -e sh ./1" > /home/$username/.config/autostart-scripts/xxx
chmod +x /home/$username/.config/autostart-scripts/xxx

echo "
tmpfs						/var/log	tmpfs	defaults,noatime 0 0
tmpfs						/var/run	tmpfs	defaults,noatime 0 0
tmpfs						/var/lock	tmpfs	defaults,noatime 0 0 " >> /etc/fstab

rm -R /home/$username/.bash_logout /home/$username/.bash_profile /home/$username/.bashrc /home/$username/Package /var/cache/pacman/pkg /boot/initramfs-linux-fallback.img
chown -R $username:users /home/$username

cp -Rf /home/$username/ArchLinux/KDE/.config/kscreenlockerrc /home/$username/.config
cp -Rf /home/$username/ArchLinux/KDE/. /root
