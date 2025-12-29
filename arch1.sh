#!/bin/bash

sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf
loadkeys ru
setfont cyr-sun16

#Синхронизация системных часов
timedatectl set-ntp true
#sleep 1

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


echo -e '\033[32m' &&
read -p "                                                                                       1 - Arch, 2 - WinArch: " OS
if [[ $OS == 1 ]]; then
  #Создание разделов
wipefs -a /dev/nvme0n1
echo -e '\033[32m' &&
(
  echo g;
  echo n;
  echo;
  echo;
  echo +200M;
  echo t;
  echo 1;
  echo n;
  echo;
  echo;
  echo;
  echo w;
) | fdisk --color=never /dev/nvme0n1

#Ваша разметка диска
echo -e '\e[31m' ; lsblk -f

#Форматирование дисков
echo -e '\033[32m'
mkfs.fat -F32 /dev/nvme0n1p1
mkfs.btrfs -f -L ArchLinux /dev/nvme0n1p2

#Монтирование дисков
mount -t btrfs /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs /dev/nvme0n1p2 /mnt
btrfs subvolume create /mnt/@home
umount /mnt
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@ /dev/nvme0n1p2 /mnt
mkdir /mnt/home /mnt/boot
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@home /dev/nvme0n1p2 /mnt/home
mount /dev/nvme0n1p1 /mnt/boot

reflector --country Russia --verbose -l 10 --sort rate --save /etc/pacman.d/mirrorlist

mount --rbind /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev

echo -e '

\e[31m==================================================================================== Установка основных пакетов ==================================\e[0m
'
echo -e '\033[32m'

pacstrap /mnt base base-devel nano linux linux-zen linux-firmware btrfs-progs iwd linux-zen-headers

echo -e '

\e[31m==================================================================================== Настройка системы ===========================================\e[0m
'
echo -e '\033[32m'
genfstab -pU /mnt >> /mnt/etc/fstab
#arch-chroot /mnt sh -c "$(curl -fsSL git.io/2.sh)"
arch-chroot -S /mnt 
#arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/DrDiablo87/ArchLinux/refs/heads/master/arch2.sh)"


elif [[ $OS == 2 ]]; then

#Создание разделов
#cfdisk /dev/nvme0n1
echo -e '\033[32m' &&
(
  echo n;
  echo;
  echo;
  echo;
  echo w;
) | fdisk --color=never /dev/nvme0n1

#Ваша разметка диска
echo -e '\e[31m' ; lsblk -f

#Форматирование дисков
echo -e '\033[32m'

mkfs.btrfs -f -L ArchLinux /dev/nvme0n1p5

#Монтирование дисков
mount -t btrfs /dev/nvme0n1p5 /mnt
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs /dev/nvme0n1p5 /mnt
btrfs subvolume create /mnt/@home
umount /mnt
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@ /dev/nvme0n1p5 /mnt
mkdir /mnt/home /mnt/boot
mount -t btrfs -o noatime,nodatasum,compress=zstd,ssd,max_inline=0,subvol=@home /dev/nvme0n1p5 /mnt/home
mount /dev/nvme0n1p1 /mnt/boot

reflector --country Russia --verbose -l 10 --sort rate --save /etc/pacman.d/mirrorlist

mount --rbind /proc /mnt/proc
mount --rbind /sys /mnt/sys
mount --rbind /dev /mnt/dev

echo -e '

\e[31m==================================================================================== Установка основных пакетов ==================================\e[0m
'
echo -e '\033[32m'

pacstrap /mnt base base-devel nano linux linux-zen linux-firmware btrfs-progs iwd linux-zen-headers

echo -e '

\e[31m==================================================================================== Настройка системы ===========================================\e[0m
'
echo -e '\033[32m'
genfstab -pU /mnt >> /mnt/etc/fstab
arch-chroot -S /mnt 
#arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/DrDiablo87/ArchLinux/refs/heads/master/arch2.sh)"

  
fi 
