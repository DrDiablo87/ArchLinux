# ArchLinux
curl -LO git.io/1.sh && sh 1.sh       <br>
pacman -Syy wget && wget git.io/1.sh && sh 1.sh       <br>
pacman -Syy wget && wget git.io/www.sh && sh www.sh
# ArchLive
sudo mkarchiso -v ~/archlive       <br>
rm out work /var/cache/pacman ~/Package/*
# Zona 2.1.0.3
Proton 10.0-3 или Experimental       <br>
Снова доблять установленную игру        <br>
"/home/www/.local/share/Steam/steamapps/compatdata/.........../pfx/drive_c/Program Files (x86)/Zona/Zona.exe"       <br>
/home/www/.local/share/Steam/steamapps/compatdata/.........../pfx/drive_c/Program Files (x86)/Zona/       <br>
PROTON_USE_WINED3D11=1 %command%
# qvkbd
Программа qvkbd       <br>
Аргументы GDK_BACKEND=x11       <br>
Запуск от root       <br>

# NVME 
Добавить новый контроллер "Последовательное VirtIO" и отредактировать        <br>
```bash
<controller type="nvme" index="0">
  <serial>4</serial>
  <alias name="nvme0"/>
  <address type="pci" domain="0x0000" bus="0x10" slot="0x02" function="0x0"/>
</controller>
```

Добавить диск VirtIO 
установить в качестве целевого устройства NVMe: 
````bash
 <target dev='nvme0n1' bus='nvme'/>
````

