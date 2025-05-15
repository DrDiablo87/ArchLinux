     #!/bin/bash
#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть
#sudo sed -i 's/Required TrustedOnly/Never/g' /etc/pacman.conf

mkdir ~/Package
#===========================================================================================
read -p "1 - VMware, 2 - VBox, 3 - PC: " driver
if [[ $driver == 1 ]]; then
  sudo pacman -S  gtkmm gtkmm3 open-vm-tools --noconfirm
  sudo systemctl enable vmtoolsd.service
  sudo systemctl start vmtoolsd.service
  echo '#!/bin/bash
  sleep 3
  sudo systemctl restart vmtoolsd.service' > ~/.config/autostart/restart && sudo chmod +x ~/.config/autostart/restart
  pkill mplayer
elif [[ $driver == 2 ]]; then
  sudo pacman -S virtualbox-host-modules-arch virtualbox-guest-utils --noconfirm
  sudo systemctl unmask vboxservice.service virtvboxd.service
  sudo systemctl enable vboxservice.service virtvboxd.service
  sudo systemctl start vboxservice.service virtvboxd.service
  sudo rm ~/.config/autostart-scripts/LiveWallpaperService ~/.config/autostart-scripts/LiveWallpaperService.desktop
  pkill mplayer
elif [[ $driver == 3 ]]; then
  echo
fi

#===========================================================================================
git config --global url."https://".insteadOf git://
yay -S --mflags --skipinteg --noconfirm profile-sync-daemon && psd -p
#systemctl --user enable psd.service
sudo ln /usr/lib/systemd/user/psd.service /usr/lib/systemd/user/Firefox.service
#yay -Rns --mflags --skipinteg --noconfirm extra-cmake-modules && yay -S --mflags --skipinteg --noconfirm extra-cmake-modules-git discover
yay -S --mflags --skipinteg --noconfirm discover flatpak
yay -S --mflags --skipinteg --noconfirm netactview loudmouth hddtemp ki18n plasma6-applets-thermal-monitor-git plasma6-applets-resources-monitor netdiscover fail2ban plasma6-applets-netspeed ffmulticonverter steghide noisy-py3-git cpu-x qvkbd kf6-servicemenus-rootactions arc-kde-git onlyoffice-bin 
yay -S --mflags --skipinteg --noconfirm lact corectrl svp-bin phonon-qt6-mpv plasma6-wallpapers-wallpaper-engine-git opencl-amd noisetorch-bin
#yay -Rns --noconfirm phonon-qt6-vlc
yay -S --mflags --skipinteg --noconfirm mkvtoolnix-gui ventoy-bin timeshift megasync mednaffe mednafen
#yay -U --mflags --skipinteg --noconfirm ~/ArchLinux/Package/mystiq-20.03.23-1-x86_64.pkg.tar.zst
sudo mv /etc/systemd/system/noisy.service /etc/systemd/system/Noisy.service
sudo mv /usr/share/noisy/examples/systemd/noisy.service /usr/share/noisy/examples/systemd/Noisy.service
#yay -S --mflags --skipinteg --noconfirm fritzing lact
yay -S --mflags --skipinteg --noconfirm airgeddon metasploit dhcp hashcat hashcat-utils tcpdump ipscan crunch mdk4 reaver beef hostapd lighttpd bettercap ettercap sslstrip dsniff bully pixiewps usbutils xorg-xdpyinfo ccze asleap john hostapd-wpe nftables mdk3 hcxtools hcxdumptool
#создать пункты
#программа     sudo
#Аргументы     msfconsole     или      airgeddon
# Запуск в терминале налочка



sudo systemctl enable fail2ban.service
yay -S --mflags --skipinteg --noconfirm mc htop ncdu edk2-ovmf virt-manager qemu dnsmasq ffmpeg yt-dlp mediainfo-gui qtqr startwine qt-heif-image-plugin-git ifuse
sudo systemctl enable libvirtd.service && sudo gpasswd -a $USER libvirt
yes | sudo sensors-detect
yes | yay -Syua && yes | yay -Scc && yes | yay -Rns $(yay -Qtdq)

mkdir ~/.compose-cache

#=============================================================================================
echo "[/home/$USER/.local/share/Trash]
Days=1
LimitReachedAction=0
Percent=10
UseSizeLimit=false
UseTimeLimit=true" > ~/.config/ktrashrc
#=============================================================================================
sudo chown -R "$USER":users ~/.
cp -r ~/ArchLinux/KDE/.* ~/

sudo rm -rf /root/.config/gtk-3.0
sudo ln -s ~/.config/gtk-3.0 /root/.config/gtk-3.0
sudo cp ~/.face.icon /usr/share/sddm/themes/breeze/faces/.face.icon

sudo cp ~/ArchLinux/Package/zshrc /etc/zsh/zshrc
sudo cp ~/ArchLinux/Package/konsolerc /root/.config/konsolerc

echo "[Containments][47][Wallpaper][org.kde.image][General]
Image=/home/$USER/.local/share/applications/screenshot.jpg" >> ~/.config/plasma-org.kde.plasma.desktop-appletsrc
echo "[Greeter][Wallpaper][org.kde.image][General]
Image=/home/$USER/.local/share/applications/screenshot.jpg
PreviewImage=/home/$USER/.local/share/applications/screenshot.jpg" > ~/.config/kscreenlockerrc
============================================================================================
curl -LO https://github.com/amnezia-vpn/amnezia-client/releases/download/4.8.5.0/AmneziaVPN_4.8.5.0_linux.tar.zip
unzip AmneziaVPN_4.8.5.0_linux.tar.zip
tar -xvf AmneziaVPN_Linux_Installer.tar
chmod +x AmneziaVPN_Linux_Installer.bin
rm -R AmneziaVPN_4.8.5.0_linux.tar.zip AmneziaVPN_Linux_Installer.tar

#============================================================================
git clone https://github.com/Kurchatov87/12345.git
sudo tar -xf ~/ArchLinux/Package/archlive.tar.gz -C ~/
#tar -xf ~/ArchLinux/Package/archlive.tar.gz -C ~/
#cp ~/archlive/airootfs/root/.mozilla ~/
#sudo chown -R root:root ~/archlive
#sudo rm -R ~/1 ~/.config/autostart-scripts/xxx ~/.config/autostart/xxx 

#qdbus org.kde.ksmserver /KSMServer logout 0 1 2  #logout 0 3 3

rm ~/.config/autostart/arch3.sh.desktop ~/.config/autostart/restart
systemctl reboot
