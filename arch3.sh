#!/bin/bash
#tourch || exit $?                 # завершение скрипта при возникновении ошибки, а она в этой комманде есть
#sudo sed -i 's/Required TrustedOnly/Never/g' /etc/pacman.conf

mkdir ~/Package
#===========================================================================================
read -p "1 - VMware, 2 - VBox, 3 - PC: " driver
if [[ $driver == 1 ]]; then
  sudo pacman -S gtkmm3 open-vm-tools --noconfirm
  sudo systemctl enable vmtoolsd.service
  sudo systemctl start vmtoolsd.service
  sudo rm ~/.config/autostart-scripts/LiveWallpaperService
  pkill mplayer
elif [[ $driver == 2 ]]; then
  sudo pacman -S virtualbox-host-modules-arch virtualbox-guest-utils --noconfirm
  sudo systemctl unmask vboxservice.service virtvboxd.service
  sudo systemctl enable vboxservice.service virtvboxd.service
  sudo systemctl start vboxservice.service virtvboxd.service
  sudo rm ~/.config/autostart-scripts/LiveWallpaperService
  pkill mplayer
elif [[ $driver == 3 ]]; then
  echo
fi

#===========================================================================================
yay -S --mflags --skipinteg --noconfirm profile-sync-daemon && psd -p
systemctl --user enable psd.service
yay -S --mflags --skipinteg --noconfirm archiso netactview loudmouth hddtemp plasma5-applets-systemd plasma5-applets-thermal-monitor plasma5-applets-resources-monitor plasma5-applets-eventcalendar netdiscover fail2ban plasma5-applets-netspeed ffmulticonverter steghide
yay -S --mflags --skipinteg --noconfirm airgeddon metasploit dhcp hashcat hashcat-utils ipscan crunch mdk4 reaver beef hostapd lighttpd bettercap ettercap sslstrip dsniff bully pixiewps usbutils xorg-xdpyinfo ccze asleap john hostapd-wpe nftables mdk3 hcxtools hcxdumptool
yay -S --mflags --skipinteg --noconfirm mkvtoolnix-gui ventoy-bin timeshift megasync fritzing mednaffe mednafen
yay -U --mflags --skipinteg --noconfirm ~/ArchLinux/Package/mystiq-20.03.23-1-x86_64.pkg.tar.zst

sudo systemctl enable fail2ban.service
yay -S --mflags --skipinteg --noconfirm libreoffice-fresh-ru unoconv

yes | sudo sensors-detect
yay -S --mflags --skipinteg --noconfirm playonlinux && wget https://install4.zonastat.com/ZonaSetup.exe && sudo rm /usr/share/applications/wine.desktop #&& yay -Rscndd wine --noconfirm
yes | yay -Syua && yes | yay -Scc && yes | yay -Rns $(yay -Qtdq)
cp -Rf ~/ArchLinux/KDE/. ~/

sudo rm -rf /root/.config/gtk-3.0
sudo ln -s ~/.config/gtk-3.0 /root/.config/gtk-3.0

sudo cp ~/.face.icon /usr/share/sddm/themes/breeze/faces/.face.icon
mkdir ~/.compose-cache

#=============================================================================================
echo "[/home/$USER/.local/share/Trash]
Days=1
LimitReachedAction=0
Percent=10
UseSizeLimit=false
UseTimeLimit=true" > ~/.config/ktrashrc
#=============================================================================================

#=============================================================================================
echo "[General]
confirmLogout=true
excludeApps=
loginMode=default
offerShutdown=true
shutdownType=0

[LegacySession: saved at previous logout]
count=0

[Session: saved at previous logout]
clientId1=10a5d4b0d8000157469050500000005630004
clientId2=10a5d4b0d8000157469392300000005650005
count=2
discardCommand1[$e]=rm,$HOME/.config/session/kwin_10a5d4b0d8000157469050500000005630004_1574694021_149533
program1=/usr/bin/kwin_x11
program2=pulseaudio
restartCommand1=/usr/bin/kwin_x11,-session,10a5d4b0d8000157469050500000005630004_1574694021_149533
restartCommand2=
restartStyleHint1=0
restartStyleHint2=0
userId1=$USER
userId2=$USER
wasWm1=true
wasWm2=false" > ~/.config/ksmserverrc
#=============================================================================================
echo "[Desktop Entry]
Comment=
Exec=airgeddon
Icon=/home/$USER/.config/LiveWallpaper/2000px-Biohazard_symbol.png
Name=Airgeddon
NoDisplay=false
Path[$e]=
StartupNotify=true
Terminal=1
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=true
X-KDE-Username=root" > ~/.local/share/applications/Airgeddon.desktop
#=============================================================================================
echo "[Desktop Entry]
Comment=
Exec=msfconsole
Icon=/home/$USER/.config/LiveWallpaper/2000px-Biohazard_symbol.svg.png
Name=Metasploit
NoDisplay=false
Path[$e]=
StartupNotify=true
Terminal=1
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=true
X-KDE-Username=root" > ~/.local/share/applications/Metasploit.desktop
#=============================================================================================
echo "[Desktop Entry]
Comment=
Exec=/usr/share/playonlinux/playonlinux --run "Zona" %F
Icon= /home/$USER/.PlayOnLinux/icones/full_size/Zona
Name=Zona
NoDisplay=false
Path[$e]=
StartupNotify=true
Terminal=0
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username=" > ~/.local/share/applications/Zona.desktop
#=============================================================================================
echo "[Desktop Entry]
Categories=GNOME;GTK;Network;Monitor;
Comment=Просмотр сетевых соединений
Exec=netactview
Icon=preferences-system-network-dsl
Name[ru_RU]=Net Activity Viewer
Name=Net Activity Viewer
NoDisplay=false
Path[$e]=
StartupNotify=true
Terminal=0
TerminalOptions=
Type=Application
X-KDE-SubstituteUID=false
X-KDE-Username= " > ~/.local/share/applications/netactview.desktop
#=============================================================================================
mkdir ~/.local/share/kate
echo "[Document 0]
Bookmarks=
Encoding=UTF-8
Highlighting=None
Highlighting Set By User=false
Indentation Mode=normal
Mode=Normal
Mode Set By User=false
URL=file:///home/$USER/.gtkrc-2.0

[Kate Plugins]
cuttlefishplugin=false
katebacktracebrowserplugin=false
katebuildplugin=false
katecloseexceptplugin=false
katectagsplugin=false
katefilebrowserplugin=true
katefiletreeplugin=true
kategdbplugin=false
katekonsoleplugin=true
kateopenheaderplugin=false
kateprojectplugin=true
katereplicodeplugin=false
katesearchplugin=true
katesnippetsplugin=false
katesqlplugin=false
katesymbolviewerplugin=false
katexmlcheckplugin=false
katexmltoolsplugin=false
kterustcompletionplugin=false
ktexteditor_lumen=false
ktexteditorpreviewplugin=false
tabswitcherplugin=true
textfilterplugin=true

[MainWindow0]
Active ViewSpace=0
Kate-MDI-H-Splitter=200,640,200
Kate-MDI-Sidebar-0-Splitter=0,0,0
Kate-MDI-Sidebar-1-Splitter=
Kate-MDI-Sidebar-2-Splitter=
Kate-MDI-Sidebar-3-Splitter=0,0,0
Kate-MDI-Sidebar-Style=2
Kate-MDI-Sidebar-Visible=false
Kate-MDI-ToolView-kate_plugin_katesearch-Persistent=false
Kate-MDI-ToolView-kate_plugin_katesearch-Position=3
Kate-MDI-ToolView-kate_plugin_katesearch-Sidebar-Position=0
Kate-MDI-ToolView-kate_plugin_katesearch-Visible=false
Kate-MDI-ToolView-kate_private_plugin_katefileselectorplugin-Persistent=false
Kate-MDI-ToolView-kate_private_plugin_katefileselectorplugin-Position=0
Kate-MDI-ToolView-kate_private_plugin_katefileselectorplugin-Sidebar-Position=2
Kate-MDI-ToolView-kate_private_plugin_katefileselectorplugin-Visible=false
Kate-MDI-ToolView-kate_private_plugin_katefiletreeplugin-Persistent=false
Kate-MDI-ToolView-kate_private_plugin_katefiletreeplugin-Position=0
Kate-MDI-ToolView-kate_private_plugin_katefiletreeplugin-Sidebar-Position=0
Kate-MDI-ToolView-kate_private_plugin_katefiletreeplugin-Visible=false
Kate-MDI-ToolView-kate_private_plugin_katekonsoleplugin-Persistent=false
Kate-MDI-ToolView-kate_private_plugin_katekonsoleplugin-Position=3
Kate-MDI-ToolView-kate_private_plugin_katekonsoleplugin-Sidebar-Position=2
Kate-MDI-ToolView-kate_private_plugin_katekonsoleplugin-Visible=false
Kate-MDI-ToolView-kateproject-Persistent=false
Kate-MDI-ToolView-kateproject-Position=0
Kate-MDI-ToolView-kateproject-Sidebar-Position=1
Kate-MDI-ToolView-kateproject-Visible=false
Kate-MDI-ToolView-kateprojectinfo-Persistent=false
Kate-MDI-ToolView-kateprojectinfo-Position=3
Kate-MDI-ToolView-kateprojectinfo-Sidebar-Position=1
Kate-MDI-ToolView-kateprojectinfo-Visible=false
Kate-MDI-V-Splitter=150,450,200
State=AAAA/wAAAAD9AAAAAAAAAoAAAAHCAAAABAAAAAQAAAAIAAAACPwAAAABAAAAAgAAAAEAAAAWAG0AYQBpAG4AVABvAG8AbABCAGEAcgAAAAAA/////wAAAAAAAAAA

[MainWindow0 Settings]
State=AAAA/wAAAAD9AAAAAAAAAoAAAAHCAAAABAAAAAQAAAAIAAAACPwAAAABAAAAAgAAAAEAAAAWAG0AYQBpAG4AVABvAG8AbABCAGEAcgAAAAAA/////wAAAAAAAAAA
WindowState=8

[MainWindow0-Splitter 0]
Children=MainWindow0-ViewSpace 0
Orientation=1
Sizes=640

[MainWindow0-ViewSpace 0]
Active View=file:///home/$USER/.gtkrc-2.0
Count=1
Documents=file:///home/$USER/.gtkrc-2.0
View 0=file:///home/$USER/.gtkrc-2.0

[MainWindow0-ViewSpace 0 file:///home/$USER/.gtkrc-2.0]
CursorColumn=0
CursorLine=0
Dynamic Word Wrap=true
JumpList=
TextFolding=[]
ViMarks=.,0,0,[,0,0,],0,0

[Open Documents]
Count=1

[Open MainWindows]
Count=1

[Plugin:katefilebrowserplugin:MainWindow:0]
Allow Expansion=false
Decoration position=2
Show Inline Previews=true
Show Preview=false
Show hidden files=false
Sort by=Name
Sort directories first=true
Sort reversed=false
View Style=DetailTree
auto sync folder=false
filter history=
location=file:///home/$USER

[Plugin:katesearchplugin:MainWindow:0]
BinaryFiles=false
CurrentExcludeFilter=-1
CurrentFilter=-1
ExcludeFilters=
ExpandSearchResults=false
Filters=
FollowSymLink=false
HiddenFiles=false
MatchCase=false
Place=1
Recursive=true
Replaces=
Search=
SearchDiskFiles=
SearchDiskFiless=
UseRegExp=false

[Recent Files]
File1[$e]=$HOME/.gtkrc-2.0
Name1[$e]=.gtkrc-2.0" > ~/.local/share/kate/anonymous.katesession
#============================================================================
git clone https://github.com/Kurchatov87/12345.git
sudo tar -xf ~/ArchLinux/Package/archlive.tar.gz -C ~/
#tar -xf ~/ArchLinux/Package/archlive.tar.gz -C ~/
#cp ~/archlive/airootfs/root/.mozilla ~/
#sudo chown -R root:root ~/archlive
sudo rm -R ~/1 ~/.config/autostart-scripts/xxx ~/ArchLinux
qdbus org.kde.ksmserver /KSMServer logout 0 1 2  #logout 0 3 3
