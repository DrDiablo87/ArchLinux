 #!/bin/bash
#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть
# Поиск недавно изменённых файлов
# sudo find ~/.local ~/.config -type f -mmin -1 -exec ls -al {} \;
mkdir ~/Package
#===========================================================================================
read -p "1 - VMware, 2 - VBox, 3 - PC: " driver
if [[ $driver == 1 ]]; then
  sudo pacman -S  gtkmm-4.0 gtkmm3 open-vm-tools --noconfirm
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
yay -S --mflags --skipinteg --noconfirm profile-sync-daemon dolphin-compress-media
sudo ln /usr/lib/systemd/user/psd.service /usr/lib/systemd/user/Firefox.service
psd -p
cp ~/ArchLinux/Package/firefox-on.png ~/.config/psd/firefox-on.png
cp ~/ArchLinux/Package/firefox-off.png ~/.config/psd/firefox-off.png
#systemctl --user start psd
#systemctl --user stop psd
#sudo systemctl start Noisy.service
#sudo systemctl stop Noisy.service

sudo ln /usr/lib/systemd/user/psd.service /usr/lib/systemd/user/Firefox.service
yay -S --mflags --skipinteg --noconfirm flatpak amneziavpn-bin
yay -S --mflags --skipinteg --noconfirm netactview loudmouth hddtemp ki18n plasma6-applets-resources-monitor netdiscover fail2ban plasma6-applets-netspeed ffmulticonverter steghide cpu-x hardinfo2 kf6-servicemenus-rootactions arc-kde-git onlyoffice-bin plasma6-applets-thermal-monitor qvkbd
yay -S --mflags --skipinteg --noconfirm phonon-qt6-mpv calf pavucontrol-qt 
yay -S --mflags --skipinteg --noconfirm ventoy-bin timeshift
yay -S --mflags --skipinteg --noconfirm airgeddon metasploit dhcp hashcat hashcat-utils tcpdump ipscan crunch mdk4 reaver beef hostapd lighttpd bettercap ettercap sslstrip dsniff bully pixiewps usbutils xorg-xdpyinfo ccze asleap john hostapd-wpe nftables mdk3 hcxtools hcxdumptool onionshare
sudo systemctl enable fail2ban.service
yay -S --mflags --skipinteg --noconfirm mc ncdu edk2-ovmf qrca qt-heif-image-plugin-git ifuse wireguard-tools wireproxy
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
yay -Rns --mflags --skipinteg --noconfirm extra-cmake-modules discover

rm ~/.config/autostart/arch3.sh.desktop ~/.config/autostart/restart
systemctl reboot
