setopt autocd
autoload -U compinit && compinit
zstyle ':completion:*' menu select
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
POWERLEVEL9K_MODE='awesome-fontconfig'
POWERLEVEL9K_LINUX_ARCH_ICON='\UF023'
POWERLEVEL9K_OS_ICON_FOREGROUND='046'    #default - delete
POWERLEVEL9K_COMMAND_EXECUTION_TIME_BACKGROUND='000'
POWERLEVEL9K_DIR_HOME_FOREGROUND='195'
POWERLEVEL9K_DIR_HOME_SUBFOLDER_FOREGROUND='195'
POWERLEVEL9K_DIR_DEFAULT_FOREGROUND='195'
POWERLEVEL9K_DIR_ETC_FOREGROUND='195'
POWERLEVEL9K_VCS_CLEAN_FOREGROUND='195'
POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='195'
POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='195'
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(command_execution_time)

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000

alias 1='yes | yay -Syyu && yes | yay -Scc && yes | yay -Rns $(yay -Qtdq)'
alias 2='sudo reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist' # обновить зеркала
alias 3='source ~/.zshrc'            # обновить терминал
alias h='history'
alias yr='yay -Rns --noconfirm'
alias yu='yay -U --mflags --skipinteg --noconfirm'
alias ys='yay -S --mflags --skipinteg --noconfirm'
alias y='yay --mflags --skipinteg --noconfirm'
alias p='yay -Ps'                    # статистика пакетов
alias pacman='sudo pacman --noconfirm'
alias c='clear'
alias ping='ping -c 5 ya.ru'         # пинг
alias ports='netstat -tulanp'        # открытые порты
alias ls='ls -Alh --color'           # показать скрытые файлы
alias du='sudo ncdu --color dark'    # показать размер файлов
alias ..='cd ..'                     # перейти в директорию уровнем выше
alias .='cd -'                       # перейти в директорию, в которой находились до перехода в текущую директорию
alias tree='tree -Cha'               # просмотр дерева директорий
alias grep='grep --color=auto'
alias mkdir='mkdir -p'
alias rm='sudo rm -rf'
alias cp='cp -r'
alias g='git clone'

alias ydl='youtube-dl --no-playlist --merge-output-format mkv -o "%(title)s.%(ext)s"'
alias ydlm='youtube-dl -x --audio-format mp3 --audio-quality 320k -o "%(title)s.%(ext)s"'
alias ydl480='youtube-dl --no-playlist --merge-output-format mkv -f "bestvideo[height<=480][fps<=30]+bestaudio/best[height<=480]" -o "%(title)s.%(ext)s"'
alias ydl720='youtube-dl --no-playlist --merge-output-format mkv -f "bestvideo[height<=720][fps<=30]+bestaudio/best[height<=720]" -o "%(title)s.%(ext)s"'
alias ydlp480='youtube-dl --skip-unavailable-fragments -i --merge-output-format mkv -f "bestvideo[height<=480][fps<=30]+bestaudio/best[height<=480]" -o "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"'
alias ydlp720='youtube-dl --skip-unavailable-fragments -i --merge-output-format mkv -f "bestvideo[height<=720][fps<=30]+bestaudio/best[height<=720]" -o "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s"'

neofetch --ascii_colors 0 0  --colors 4 4 1 6 7 2
echo -ne '\e[1 q'                    # Вид курсора от 1-6
