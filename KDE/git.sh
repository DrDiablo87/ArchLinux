#!/bin/bash

#Имя аккаунта Git: qwerty
#Название репозитория Git: 12345
#Почта аккаунта Git: qwerty@mail.ru
#Пароль аккаунта Git: youpassword

#git clone https://github.com/qwerty/12345.git
#cd ~/12345
#git remote set-url origin https://qwerty:youpassword123@github.com/qwerty/12345.git
#sudo git config --system user.name qwerty
#sudo git config --system user.email qwerty@mail.ru
#sudo git config --system core.editor kate
#sudo git config --system diff.tool kompare
#cd ~/
#=====================================================================
sudo mkdir -p /root/.config/gtk-3.0 && sudo cp -R ~/.config/gtk-3.0 /root/.config
read -p "Имя аккаунта Git: " namegit
read -p "Название репозитория Git: " namerep
read -p "Почта аккаунта Git: " mailgit
read -p "Пароль аккаунта Git: " passgit

git clone https://github.com/$namegit/$namerep.git
cd ~/$namerep
git remote set-url origin https://$namegit:$passgit@github.com/$namegit/$namerep.git
sudo git config --system user.name $namegit
sudo git config --system user.email $mailgit
sudo git config --system core.editor kate
sudo git config --system diff.tool kompare
cd ~/

