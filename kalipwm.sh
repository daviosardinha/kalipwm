#!/bin/bash

# Colores
GREEN=$(tput setaf 2)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
RESET=$(tput sgr0)

# Comprobar si el usuario actual es root
if [ "$UID" -eq 0 ]; then
    echo -e "${RED}[-] No se puede ejecutar como root.${RESET}"
    exit 1
else
    if [ -n "$SUDO_USER" ]; then
        echo -e "${RED}[-] No uses sudo.${RESET}"
        exit 1
    fi
fi

echo -e "${GREEN}
@@@  @@@   @@@@@@   @@@       @@@  @@@@@@@   @@@  @@@  @@@  @@@@@@@@@@
@@@  @@@  @@@@@@@@  @@@       @@@  @@@@@@@@  @@@  @@@  @@@  @@@@@@@@@@@
@@!  !@@  @@!  @@@  @@!       @@!  @@!  @@@  @@!  @@!  @@!  @@! @@! @@!
!@!  @!!  !@!  @!@  !@!       !@!  !@!  @!@  !@!  !@!  !@!  !@! !@! !@!
@!@@!@!   @!@!@!@!  @!!       !!@  @!@@!@!   @!!  !!@  @!@  @!! !!@ @!@
!!@!!!    !!!@!!!!  !!!       !!!  !!@!!!    !@!  !!!  !@!  !@!   ! !@!
!!: :!!   !!:  !!!  !!:       !!:  !!:       !!:  !!:  !!:  !!:     !!:
:!:  !:!  :!:  !:!   :!:      :!:  :!:       :!:  :!:  :!:  :!:     :!:
 ::  :::  ::   :::   :: ::::   ::   ::        :::: :: :::   :::     ::
 :   :::   :   : :  : :: : :  :     :          :: :  : :     :      :
"

sleep 2
echo -e "[+] Script de automatización de entorno de hacking profesional.${RESET}"
sleep 1
echo -e "[+] @afsh4ck - Sígueme en: YouTube, Instagram, TikTok"
sleep 3
echo -e "\n${BLUE}[*] Configurando la instalación..${RESET}\n"
sleep 3

RPATH=`pwd`

echo -e "\n${BLUE}[*] Actualizando paquetes..${RESET}\n"
sudo apt update

echo -e "\n${BLUE}[*] Instalando paquetes..${RESET}\n"
sudo apt install -y git bspwm vim feh scrot scrub zsh rofi xclip xsel locate wmname acpi sxhkd \
    imagemagick ranger kitty tmux python3-pip font-manager lsd bat bpython open-vm-tools-desktop open-vm-tools fastfetch \
    dirsearch feroxbuster gedit curl wget unzip papirus-icon-theme lm-sensors pavucontrol network-manager i3lock jq

echo -e "\n${BLUE}[*] Instalando dependencias del entorno..${RESET}\n"
sudo apt install -y build-essential libxcb-util0-dev libxcb-ewmh-dev libxcb-randr0-dev \
    libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libasound2-dev libxcb-xtest0-dev libxcb-shape0-dev

echo -e "\n${BLUE}[*] Instalando requisitos de polybar..${RESET}\n"
sudo apt install -y cmake cmake-data pkg-config python3-sphinx libcairo2-dev libxcb1-dev libxcb-util0-dev \
    libxcb-randr0-dev libxcb-composite0-dev python3-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev \
    libxcb-icccm4-dev libxcb-xkb-dev libxcb-xrm-dev libxcb-cursor-dev libasound2-dev libpulse-dev libjsoncpp-dev \
    libmpdclient-dev libuv1-dev libnl-genl-3-dev

echo -e "\n${BLUE}[*] Instalando dependencias de picom..${RESET}\n"
sudo apt install -y meson libxext-dev libxcb1-dev libxcb-damage0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
    libxcb-render-util0-dev libxcb-render0-dev libxcb-composite0-dev libxcb-image0-dev libxcb-present-dev \
    libxcb-xinerama0-dev libpixman-1-dev libdbus-1-dev libconfig-dev libgl1-mesa-dev libpcre2-dev libevdev-dev \
    uthash-dev libev-dev libx11-xcb-dev libxcb-glx0-dev libpcre3 libpcre3-dev

echo -e "\n${BLUE}[*] Instalando fuentes..${RESET}\n"
mkdir -p /tmp/fonts
wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/fonts/Hack.zip
unzip -q /tmp/fonts/Hack.zip -d /tmp/fonts
mkdir -p ~/.local/share/fonts
mv /tmp/fonts/*.ttf ~/.local/share/fonts/
rm -rf /tmp/fonts
fc-cache -fv

mkdir -p /tmp/fonts
wget -q --show-progress https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip -O /tmp/fonts/JetBrainsMono.zip
unzip -q /tmp/fonts/JetBrainsMono.zip -d /tmp/fonts
mv /tmp/fonts/*.ttf ~/.local/share/fonts/
rm -rf /tmp/fonts
fc-cache -fv

echo -e "\n${BLUE}[*] Instalando OhMyZSH..${RESET}\n"
rm -rf ~/.oh-my-zsh
yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo -e "\n${BLUE}[*] Instalando tema powerlevel10k..${RESET}\n"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm -f ~/.p10k.zsh
cp -v $RPATH/CONFIGS/p10k.zsh ~/.p10k.zsh

echo -e "\n${BLUE}[*] Instalando plugins de ZSH..${RESET}\n"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
rm -f ~/.zshrc
cp -v $RPATH/CONFIGS/zshrc ~/.zshrc

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
yes | ~/.fzf/install

rm -rf ~/.tmux
git clone https://github.com/gpakosz/.tmux.git ~/.tmux
ln -s -f ~/.tmux/.tmux.conf ~/
cp -v $RPATH/CONFIGS/tmux.conf.local ~/.tmux.conf.local

echo -e "\n${BLUE}[*] Instalando terminal kitty..${RESET}\n"
/usr/bin/cat $RPATH/kitty-installer.sh | sh /dev/stdin

mkdir -p ~/github
git clone --recursive https://github.com/polybar/polybar ~/github/polybar
git clone https://github.com/ibhagwan/picom.git ~/github/picom

echo -e "\n${BLUE}[*] Instalando polybar..${RESET}\n"
cd ~/github/polybar
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install

echo -e "\n${BLUE}[*] Instalando temas de polybar..${RESET}\n"
git clone --depth=1 https://github.com/adi1090x/polybar-themes.git ~/github/polybar-themes
chmod +x ~/github/polybar-themes/setup.sh
cd ~/github/polybar-themes
echo 1 | ./setup.sh

echo -e "\n${BLUE}[*] Instalando picom..${RESET}\n"
cd ~/github/picom
git submodule update --init --recursive
meson --buildtype=release . build
ninja -C build
sudo ninja -C build install

echo -e "\n${BLUE}[*] Instalando configuraciones..${RESET}\n"
sudo timedatectl set-timezone "Europe/Lisbon"

mkdir -p ~/screenshots

cp -rv $RPATH/CONFIGS/config/* ~/.config/
cp -rv $RPATH/SCRIPTS/* ~/.config/polybar/forest/scripts/
cp -v $RPATH/SCRIPTS/screenshot.sh ~/.config/polybar/obsidian/scripts/screenshot.sh
sudo ln -sf ~/.config/polybar/obsidian/scripts/target.sh /usr/bin/target
sudo ln -sf ~/.config/polybar/obsidian/scripts/screenshot.sh /usr/bin/screenshot

mkdir -p ~/Wallpapers/
cp -rv $RPATH/WALLPAPERS/* ~/Wallpapers/

for wallpaper in \
    ~/Wallpapers/obsidian/obsidian-city-16x9.jpg \
    ~/Wallpapers/obsidian/obsidian-city-ultrawide.jpg; do
    if [ ! -s "$wallpaper" ] || ! identify "$wallpaper" >/dev/null 2>&1; then
        echo -e "${RED}[-] Invalid Obsidian wallpaper: $wallpaper${RESET}"
        exit 1
    fi
done

chmod +x ~/.config/bspwm/bspwmrc
chmod +x ~/.config/bspwm/scripts/bspwm_resize
chmod +x ~/.config/bspwm/scripts/set-obsidian-wallpaper.sh
chmod +x ~/.config/polybar/obsidian/launch.sh
chmod +x ~/.config/polybar/obsidian/scripts/*.sh
chmod +x ~/.config/polybar/obsidian-v2/launch.sh
chmod +x ~/.config/polybar/obsidian-v2/scripts/*.sh
chmod +x ~/.config/polybar/forest/scripts/target.sh
chmod +x ~/.config/polybar/forest/scripts/screenshot.sh

# Apply the bundled Obsidian wallpaper immediately when installing from a graphical session.
if [ -n "${DISPLAY:-}" ] && command -v xrandr >/dev/null 2>&1 && command -v feh >/dev/null 2>&1; then
    ~/.config/bspwm/scripts/set-obsidian-wallpaper.sh auto || \
        echo -e "${RED}[!] Wallpaper was installed but could not be applied in the current session.${RESET}"
fi

echo -e "\n${BLUE}[+] Entorno desplegado, Happy Hacking ;)${RESET}\n"
echo -e "${BLUE}[+] Obsidian v2 activo por defecto.${RESET}\n"
echo -e "${BLUE}[+] Wallpapers Obsidian JPEG instalados y seleccionados automaticamente por monitor.${RESET}\n"
echo -e "${BLUE}[+] cat usa /usr/bin/cat y vim usa /usr/bin/vim.${RESET}\n"
echo -e "${BLUE}[+] Por favor, reinicia el equipo (sudo reboot)${RESET}\n"
