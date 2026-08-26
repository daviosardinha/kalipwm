# KaliPWM — Obsidian

Fork modificado de KaliPWN con el tema **Obsidian** para Kali Linux, BSPWM, Polybar, Rofi y Kitty.

## Instalación y uso

Se recomienda una instalación nueva/limpia de Kali Linux.

```bash
git clone https://github.com/daviosardinha/kalipwm.git
cd kalipwm
bash kalipwm.sh
sudo reboot
```

Para elegir el wallpaper durante la instalación:

```bash
bash kalipwm.sh --list-wallpapers
bash kalipwm.sh --wallpaper nomad-monolith
bash kalipwm.sh --wallpaper nomad-monolith-16x9
bash kalipwm.sh --wallpaper nomad-emblem
bash kalipwm.sh --wallpaper nomad-emblem-16x9
bash kalipwm.sh --wallpaper city-16x9
bash kalipwm.sh --wallpaper city-ultrawide
```

`auto` sigue siendo la opción por defecto y selecciona automáticamente el wallpaper City adecuado según la geometría del monitor. La elección realizada con `--wallpaper` se guarda y se restaura al iniciar BSPWM.

También puedes cambiarlo después de instalar:

```bash
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-emblem-16x9
```

Una vez reiniciado, cambia a BSPWM en la pantalla de inicio de sesión.

## Wallpapers Obsidian

Los wallpapers incluidos se instalan en `~/Wallpapers/obsidian/`:

- `obsidian-city-16x9.jpg`
- `obsidian-city-ultrawide.jpg`
- `obsidian-nomad-monolith-standard.png`
- `obsidian-nomad-monolith-16x9.png`
- `obsidian-nomad-emblem-standard.png`
- `obsidian-nomad-emblem-16x9.png`

## Comandos

> [!NOTE]
> En macOS, cambia Windows por Command, y Alt por Option.

| Comando | Descripción |
|---|---|
| `Windows + Enter` | Abre una nueva terminal |
| `Windows + Flechas` | Navega entre ventanas abiertas |
| `Windows + Tab` | Cambia entre los dos escritorios más recientes |
| `Windows + Alt + R` | Recarga el entorno de escritorio |
| `Windows + Alt + Q` | Reinicia BSPWM |
| `Windows + Alt + Flechas` | Redimensiona la ventana actual |
| `Windows + Shift + F` | Abre Firefox |
| `Windows + Shift + B` | Abre Burp Suite |
| `Windows + Shift + A` | Abre Thunar |
| `Windows + Shift + Flechas` | Mueve la ventana actual |
| `target 10.0.0.1` | Selecciona una IP de destino y la muestra en Polybar |
| `target reset` | Elimina el objetivo seleccionado |
| `tmux` | Inicia tmux |
| `p10k configure` | Configura Powerlevel10K |

## Obsidian Polybar

La barra Obsidian muestra, entre otros datos:

- Wi-Fi e IP local
- VPN e IP
- Target actual
- CPU y temperatura
- GPU y temperatura
- RAM
- ventilador
- volumen
- batería / alimentación
- hora

## Paquetes principales

- BSPWM
- Polybar
- Oh My Zsh + plugins
- Powerlevel10k
- Hack Nerd Font
- JetBrainsMono Nerd Font
- Python + pip + bpython
- tmux
- Kitty
- lsd
- Vim
- Fastfetch
- feh
- Rofi
- sxhkd
- Picom

## Créditos

Este repositorio es un fork y una versión modificada de KaliPWN de **afsh4ck**.

- Proyecto original: `afsh4ck/kalipwm`
- Autor original: afsh4ck
