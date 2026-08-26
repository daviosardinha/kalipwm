# KaliPWM — Obsidian

Fork modificado de KaliPWN con un entorno **Obsidian** para Kali Linux basado en BSPWM, Polybar, Rofi, Kitty y Powerlevel10k.

> Proyecto original: `afsh4ck/kalipwm`.

## Características principales

- BSPWM con escritorios `I` a `X`.
- Polybar Obsidian v2 con Wi-Fi, VPN, Target, CPU/GPU, temperaturas, RAM, ventilador, volumen, batería/alimentación y hora.
- Selector de wallpapers durante la instalación y en tiempo de ejecución.
- Wallpapers City y Nomad Kingdom incluidos en variantes estándar, 16:9 y ultrawide donde aplica.
- Target persistente por usuario, independiente de la conexión VPN.
- Rofi con launcher y menú de energía/confirmación adaptados al tema Obsidian.
- `cat` usa `/usr/bin/cat` y `vim` usa `/usr/bin/vim`.

## Instalación

Se recomienda una instalación nueva/limpia de Kali Linux.

Ejecuta el instalador como tu usuario normal; **no ejecutes `kalipwm.sh` con sudo**. El script solicitará privilegios cuando sean necesarios.

```bash
git clone https://github.com/daviosardinha/kalipwm.git
cd kalipwm
bash kalipwm.sh
sudo reboot
```

Después del reinicio, selecciona **BSPWM** en la pantalla de inicio de sesión.

Para ver la ayuda:

```bash
bash kalipwm.sh --help
```

## Selector de wallpapers

Lista las opciones disponibles:

```bash
bash kalipwm.sh --list-wallpapers
```

Opciones actuales:

| Selector | Wallpaper |
|---|---|
| `auto` | Selección automática del City según geometría del monitor |
| `city-16x9` | Obsidian City 16:9 |
| `city-ultrawide` | Obsidian City ultrawide |
| `nomad-monolith` | Nomad Monolith estándar |
| `nomad-monolith-16x9` | Nomad Monolith 16:9 |
| `nomad-emblem` | Nomad Emblem estándar |
| `nomad-emblem-16x9` | Nomad Emblem 16:9 |

Ejemplo durante la instalación:

```bash
bash kalipwm.sh --wallpaper nomad-monolith-16x9
```

Si no indicas `--wallpaper`, se utiliza `auto`.

La elección se guarda y BSPWM vuelve a aplicarla al iniciar la sesión.

### Cambiar wallpaper después de instalar

```bash
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-monolith
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-monolith-16x9
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-emblem
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-emblem-16x9
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh city-16x9
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh city-ultrawide
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh auto
```

Los archivos se instalan en:

```text
~/Wallpapers/obsidian/
```

Wallpapers incluidos:

```text
obsidian-city-16x9.jpg
obsidian-city-ultrawide.jpg
obsidian-nomad-monolith-standard.png
obsidian-nomad-monolith-16x9.png
obsidian-nomad-emblem-standard.png
obsidian-nomad-emblem-16x9.png
```

## Target en Polybar

Selecciona un objetivo:

```bash
target 10.10.10.10
```

Polybar mostrará:

```text
Target 10.10.10.10
```

Consulta el objetivo actual:

```bash
target
```

Elimínalo:

```bash
target reset
```

El Target es estado local del escritorio y **no requiere una VPN activa**. Se almacena por usuario bajo `~/.cache/kalipwm/`.

## Obsidian Polybar v2

La barra muestra de forma compacta:

- interfaz Wi-Fi + IP local;
- VPN + IP cuando está disponible;
- Target actual;
- CPU + temperatura;
- GPU + temperatura;
- RAM utilizada;
- RPM de ventilador en formato compacto;
- volumen;
- batería y alimentación AC;
- hora;
- menú de energía.

Los iconos utilizan Nerd Fonts y el layout está diseñado para mantener la telemetría útil sin convertir la barra en una salida completa de `sensors`.

## Atajos principales

> En macOS, cambia Windows por Command y Alt por Option.

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
| `tmux` | Inicia tmux |
| `p10k configure` | Configura Powerlevel10k |

## Componentes principales

- BSPWM
- Polybar
- Rofi
- sxhkd
- Picom
- Kitty
- Oh My Zsh + plugins
- Powerlevel10k
- Hack Nerd Font
- JetBrainsMono Nerd Font
- Vim
- tmux
- Python / pip / bpython
- lsd
- Fastfetch
- feh
- lm-sensors
- pavucontrol

## Créditos y licencia

Este repositorio es un fork y una versión modificada de KaliPWN de **afsh4ck**.

- Proyecto original: `afsh4ck/kalipwm`
- Autor original: afsh4ck
- Licencia: MIT
