#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

# Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.

ln -svf /usr/share/zoneinfo/Europe/Moscow /etc/localtime

echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
echo "ru_RU.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

#ps -p 1 -o comm=


##timedatectl set-ntp yes
echo 'LANG="ru_RU.UTF-8"' > /etc/locale.conf
echo 'KEYMAP=ru
FONT=cyr-sun16' > /etc/vconsole.conf

systemctl start NetworkManager.service
#sed -i 's!/usr/share/sddm/themes/breeze/screenshot.jpg!/root/.config/LiveWallpaper/screenshot.jpg!' /usr/share/sddm/themes/breeze/theme.conf
chmod +x /usr/bin/steghide-kdialog
chmod +x /usr/bin/mpv_single
chmod +x /root/.config/autostart-scripts/1.sh
echo 'logfile = /var/log/i2pd/i2pd.log
ipv4 = true
ipv6 = false
[http]
address = 127.0.0.1
port = 7070
[httpproxy]
address = 127.0.0.1
port = 4444
[socksproxy]
address = 127.0.0.1
port = 4447
outproxy.enabled = true
outproxy = 127.0.0.1
outproxyport = 9050
[sam]
enabled = true
[reseed]
verify = true' > /etc/i2pd.conf
cp -r /root/usr /
rm -rf /root/usr

