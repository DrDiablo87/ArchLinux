#!/bin/bash

#loadkeys ru
#setfont cyr-sun16

#Синхронизация системных часов
#timedatectl set-ntp true
#sleep 10

clear
echo -e '\e[1;34m
                                                                                                        #                                               
                                                                                                       ###                                                   
                                                                                                      #+++#                                                
                                                                                                     +######                                               
                                                                                                    +########                                              
                                                                                                   ##########%                                             
                                                                                                  ##%########%%                                            
                                                                                                  #%%%#####%%%%%                                           
                                                                                                 #%%%###++##%%%%%                                          
                                                                                                #%%%%##++++##%%%%%                                         
                                                                                               #%%%%##+++++##%%%%%#                                        
                                                                                              #%%%%%##++**+###%%%%%%                                       
                                                                                             #%%%%%%###+**+###%%%%%%                                       
                                                                                            #%%%%%%%###+**++###%%%%%@                                      
                                                                                           #%%%%%%%####+**+++###%%%%%@                                     
                                                                                           %%%%%%%%####++**++####%%%%%%                                    
                                                                                         +#%%%%%%######+++*+++####%%%%%%                                   
                                                                                         #%%%#%%%########+++++#####%%%%%%                                  
                                                                                        +%%%%#%%#%%%%%%@@@@%%#######%%%%%%                                 
                                                                                       #%%%%#####%%@@@@@@@@@@@@%%%##%%%%%%%                                
                                                                                      #%%%%%###%%@@@@@@@@@@@@@@@@@%%%%%%%%%#                               
                                                                                    %#%%%%%###%@@@@@@@@@@@@@@@@@@@@@%%%%%%%%%                              
                                                                                   +#%%%%%##%@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%%%                             
                                                                                  +#%%%%%#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%%@#                            
                                                                                 +#%%%%#%@@@@@@@@@@%# #######%@@@@@@@@@@%%%%%%@                            
                                                                                +%%%%%#%@@@@@@@@* *##       ### %@@@@@@@@%%%%%%%                           
                                                                               +%%%%###@@@@@@%  #*%           ##%  %@@@@@@%#%%%%%                          
                                                                              +%%%%#+#@@@@@@   %###            %#%   @@@@@@###%%%%                         
                                                                             +%%%##+#%@@@@%    ##%      __     ###%   %@@@@%###%%%%                        
                                                                            #%%%##++%@@@@%     #### *:*++####  ###%    %@@@@#+##%%%%                       
                                                                          +#%%%##++%@@@@%      ###############*####     %@@@%#+##%%%%                      
                                                                         *#%%%##++#%@@@@    +:++#####       *#####%%#    %@@@%++##%%%%                     
                                                                        *#%%%##++#%%@@@   *#%%%%%%#####%%%######%%%%%%%#  @@@%#++##%%%%                    
                                                                       *%%%%##+++#%@@@% ##@@%# #%@%@%%%   %%%%@#+%  %@@@% %@@%%+++##%%%%                   
                                                                      +%%%%##+++#%%@@@  @@*    %@@  %@%   #@@  @@@     %@% @@%%#+++#%%%%%                  
                                                                     +%%%%%#+*+#%%%@@@ #@       @@@   @@@@@@   @@%      %@ @@%%#+*+##%%%%%                 
                                                                    #%%%%%#+*+#%%@@@@@ %%        @@%   @@@@   @@@        % @@@%%#+++##%%%%%                
                                                                  ##%%%%%#+++%@@@@@@@@  #         %@@@@@@@@%@@@%        ## @@@@@%##%%%%%%%%%               
                                                                 *#%%%%%##%@@@@@@@@@@@  ##           +@@@@@@%           #  @@@@@@@%##%%%%%%%%              
                                                                +#%%%%%%@@@@@@@@@@@@@@%   ##       *%@@@%@@@@@%       ##   @@@@@@@@@%%%%%%#%%%             
                                                               +%%%%%%@@@@@@@@@@@@@@@@%     %@@%%%@@@@%    %@@@@@@%%%%    %@@@@@@@@@@@@%%%%%%%%             
                                                              +%%%%%@@@@@@@@@@@@@@@@@%#                                   @@@@@@@@@@@@@@@%%%%%%#           
                                                             +%%%%@@@@@@@@@@@@@%#                                             @@@@@@@@@@@@@%%%%%%          
                                                            #%%%@@@@@@@@@@@%                                                      %@@@@@@@@@@%%%%%         
                                                          %#%%@@@@@@@@@%                                                              @@@@@@@@@%%%%        
                                                         +#%@@@@@@@@%                                                                    %@@@@@@@%%%%      
                                                        +%@@@@@@@%                                                                           @@@@@@@@%     
                                                       +%@@@@@%#                                                                               @@@@@@@%    
                                                      +%@@@@%                                                                                     @@@@@@   
                                                     %@@@@%                                                                                         @@@@@ 
                                                    @@%%                                                                                              %%@@ \e[0m'
echo -e '\033[32m'
read -p "                                                                                       Введите имя компьютера: " hostname
read -p "                                                                                       Введите имя пользователя: " username
read -p "                                                                                       Введите пароль root: " rootpass
read -p "                                                                                       Введите пароль user: " userpass
export hostname username rootpass userpass

echo -e '\033[32m' &&
read -p "                                                                                       1 - Arch, 2 - WinArch: " OS
if [[ $OS == 1 ]]; then
  #Создание разделов
wipefs -a /dev/sda
echo -e '\033[32m' &&
(
  echo g;
  echo n;
  echo;
  echo;
  echo +100M;
  echo t;
  echo 1;
  echo n;
  echo;
  echo;
  echo;
  echo w;
) | fdisk --color=never /dev/sda

#Ваша разметка диска
echo -e '\e[31m' ; lsblk -f

#Форматирование дисков
echo -e '\033[32m'
mkfs.fat -F32 /dev/sda1
mkfs.btrfs -f -L ArchLinux /dev/sda2

#Монтирование дисков
mount -t btrfs /dev/sda2 /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs /dev/sda2 /mnt
btrfs subvolume create /mnt/@home
umount /mnt
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@ /dev/sda2 /mnt
mkdir /mnt/home /mnt/boot
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@home /dev/sda2 /mnt/home
mount /dev/sda1 /mnt/boot

#Выбор зеркал для загрузки
echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

echo -e '

\e[31m==================================================================================== Установка основных пакетов ==================================\e[0m
'
echo -e '\033[32m'

echo 'ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
PRESETS=default
default_image="/boot/initramfs-linux.img"' > /mnt/etc/mkinitcpio.d/linux.preset
echo 'ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-zen"
PRESETS=default
default_image="/boot/initramfs-linux-zen.img"' > /mnt/etc/mkinitcpio.d/linux-zen.preset

pacstrap /mnt base base-devel nano linux linux-zen linux-firmware iptables-nft

echo -e '

\e[31m==================================================================================== Настройка системы ===========================================\e[0m
'
echo -e '\033[32m'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL git.io/2.sh)"
systemctl reboot

elif [[ $OS == 2 ]]; then

#Создание разделов
cfdisk /dev/sda

#Ваша разметка диска
echo -e '\e[31m' ; lsblk -f

#Форматирование дисков
echo -e '\033[32m'

mkfs.btrfs -f -L ArchLinux /dev/sda5

#Монтирование дисков
mount -t btrfs /dev/sda5 /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs /dev/sda5 /mnt
btrfs subvolume create /mnt/@home
umount /mnt
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@ /dev/sda5 /mnt
mkdir /mnt/home /mnt/boot
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@home /dev/sda5 /mnt/home
mount /dev/sda1 /mnt/boot

#Выбор зеркал для загрузки
echo "Server = https://mirror.yandex.ru/archlinux/\$repo/os/\$arch
Server = http://mirror.yandex.ru/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist

echo -e '

\e[31m==================================================================================== Установка основных пакетов ==================================\e[0m
'
echo -e '\033[32m'
pacstrap /mnt base base-devel nano linux linux-firmware

echo -e '

\e[31m==================================================================================== Настройка системы ===========================================\e[0m
'
echo -e '\033[32m'
genfstab -pU /mnt >> /mnt/etc/fstab

arch-chroot /mnt sh -c "$(curl -fsSL git.io/2.sh)"
systemctl reboot
  
fi 
