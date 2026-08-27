# KaliPWM Obsidian

**A dark, telemetry-first Kali Linux workspace built for offensive-security labs, CTFs, research and daily security work.**

KaliPWM Obsidian started as a fork of [`afsh4ck/kalipwm`](https://github.com/afsh4ck/kalipwm), but this repository is being developed as its own opinionated desktop environment rather than a visual copy of the upstream project.

The goal is simple: take a clean Kali installation and turn it into a repeatable, keyboard-driven workstation with an Obsidian visual language, useful live telemetry, fast target/VPN awareness and predictable behavior across bare metal and virtual machines.

<img width="2559" height="1599" alt="image" src="https://github.com/user-attachments/assets/db343d51-3ffe-40b4-ba8b-7856a4c54112" />


## What makes this fork different

KaliPWM Obsidian is moving beyond a one-shot theme installer. The project is being shaped around four principles:

- **Operational first** — the desktop should surface information useful during real security work, not just look good.
- **Repeatable** — a fresh VM and a physical Kali machine should converge on the same working environment.
- **Minimal friction** — common actions such as setting a target, changing wallpaper, checking VPN state or launching tools should take one command or shortcut.
- **Maintainable** — installation, diagnostics, rollback and documentation should evolve together instead of accumulating machine-specific fixes.

## Screenshots

These are real screenshots captured while testing this fork. They are not inherited from the upstream project.

### Obsidian on the primary Kali host
<img width="2559" height="1599" alt="image" src="https://github.com/user-attachments/assets/be265834-c305-4544-a6bd-beda88abbed7" />


### Obsidian in VMware

<img width="2555" height="1545" alt="image" src="https://github.com/user-attachments/assets/b90a9384-3fc8-4d17-a9ba-0744a04913a7" />


### Obsidian v2 Polybar

![KaliPWM Obsidian v2 Polybar telemetry](docs/screenshots/obsidian-polybar.jpg)

## Current Obsidian experience

The current stable `main` includes:

- BSPWM with Roman-numeral workspaces `I` through `X`.
- Obsidian v2 Polybar with Wi-Fi interface/IP, VPN telemetry, Target state, CPU/GPU data, temperatures, RAM, fan RPM, audio, battery/AC and time.
- Persistent per-user Target state that does **not** depend on VPN connectivity.
- Obsidian Rofi launcher and compact power confirmation UI.
- Selectable City and Nomad Kingdom wallpaper families.
- Persistent wallpaper choice across BSPWM sessions.
- Kitty + Powerlevel10k + Oh My Zsh workflow.
- Native `/usr/bin/cat` and `/usr/bin/vim` behavior.
- Dedicated Nerd Font sizing for compact telemetry and larger status icons.

## Wallpaper collection

The bundled Obsidian wallpaper library lives under [`WALLPAPERS/obsidian/`](WALLPAPERS/obsidian/).

Current families include:

- Obsidian City — 16:9 and ultrawide
- Nomad Monolith — standard and 16:9
- Nomad Emblem — standard and 16:9

Example:

![Nomad Emblem 16:9](WALLPAPERS/obsidian/obsidian-nomad-emblem-16x9.png)

## Installation

A clean or fresh Kali Linux installation is recommended while the project is still being hardened for upgrades and repair workflows.

Run the installer as your normal user. **Do not run `kalipwm.sh` with `sudo`**; the installer requests elevation only where required.

```bash
git clone https://github.com/daviosardinha/kalipwm.git
cd kalipwm
bash kalipwm.sh
sudo reboot
```

After reboot, select **BSPWM** from the login session menu.

To inspect installer options:

```bash
bash kalipwm.sh --help
```

## Wallpaper selector

List the bundled choices:

```bash
bash kalipwm.sh --list-wallpapers
```

Current wallpaper names:

| Selector | Wallpaper |
|---|---|
| `auto` | Automatically chooses the City variant based on monitor geometry |
| `city-16x9` | Obsidian City 16:9 |
| `city-ultrawide` | Obsidian City ultrawide |
| `nomad-monolith` | Nomad Monolith standard |
| `nomad-monolith-16x9` | Nomad Monolith 16:9 |
| `nomad-emblem` | Nomad Emblem standard |
| `nomad-emblem-16x9` | Nomad Emblem 16:9 |

Runtime switching is currently handled by:

```bash
~/.config/bspwm/scripts/set-obsidian-wallpaper.sh nomad-monolith-16x9
```

The chosen wallpaper is stored under `~/.cache/kalipwm/` and restored by BSPWM.

> **Development note:** a cleaner standalone `wallpaper` command and strict separation between "change wallpaper" and "run the installer" are currently being validated before they move to `main`.

## Target workflow

Set a target:

```bash
target 10.10.10.10
```

Polybar displays:

```text
Target 10.10.10.10
```

Read or clear it:

```bash
target
target reset
```

Target state is local desktop state stored per user under `~/.cache/kalipwm/`. It works with or without an active VPN.

## Obsidian Polybar v2

The bar is deliberately compact. Detailed sensor information remains available from the underlying tools, while Polybar focuses on the information that is useful at a glance:

- Wi-Fi interface + local IP
- VPN interface + VPN IP
- current Target
- CPU usage + temperature
- GPU usage + temperature when available
- used RAM
- compact fan RPM
- volume
- AC/battery state
- time
- power menu

Hardware-adaptive module visibility and improved bare-metal/VM detection are planned as part of the next reliability phase.

## Main shortcuts

> On macOS-hosted keyboards, substitute Windows/Super with Command where appropriate and Alt with Option.

| Shortcut | Action |
|---|---|
| `Super + Enter` | Open Kitty |
| `Super + D` | Open the Obsidian launcher |
| `Super + Arrow keys` | Move focus between windows |
| `Super + Tab` | Return to the previous desktop |
| `Super + Alt + R` | Reload the desktop environment |
| `Super + Alt + Q` | Restart/quit BSPWM according to the configured binding |
| `Super + Alt + Arrow keys` | Resize the focused window |
| `Super + Shift + F` | Open Firefox |
| `Super + Shift + B` | Open Burp Suite |
| `Super + Shift + A` | Open Thunar |
| `Print` | Screenshot workflow |

## Project roadmap

The detailed roadmap lives in [`ROADMAP.md`](ROADMAP.md), while completed user-visible changes are recorded in [`CHANGELOG.md`](CHANGELOG.md).

At a glance:

- ✅ Obsidian v2 desktop and Polybar foundation
- ✅ Target state and VPN-independent target display
- ✅ Obsidian wallpaper library and persistent selection
- ✅ Rofi power-menu cleanup
- 🚧 Flameshot as the default screenshot workflow
- 🚧 standalone wallpaper command / installer separation
- ⏳ `kalipwm doctor` diagnostics
- ⏳ idempotent update/repair workflow
- ⏳ hardware and VM auto-detection
- ⏳ configuration backup and rollback
- ⏳ Rofi-based KaliPWM Control Center
- ⏳ reproducibility/security hardening and a tagged `v1.0.0`

## Project language

**English is the only language used for KaliPWM Obsidian documentation, user-facing CLI output, comments and newly maintained project content.**

Legacy strings inherited from the upstream project will be migrated to English as part of the ongoing cleanup. New changes must not introduce non-English user-facing text.

## Documentation policy

Documentation is part of the definition of done for this project.

When a task is validated and lands on `main`, the same completion cycle must update the relevant README, roadmap and/or changelog entry. Features that are still experimental stay marked as **in progress** and must not be documented as stable until they are merged into `main`.

This keeps the public repository aligned with what a fresh clone can actually reproduce.

## Core components

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

## Credits and license

KaliPWM Obsidian is a fork and modified continuation of KaliPWN/KaliPWM by **afsh4ck**.

- Original project: [`afsh4ck/kalipwm`](https://github.com/afsh4ck/kalipwm)
- Original author: afsh4ck
- This fork: `daviosardinha/kalipwm`
- License: MIT

The upstream project deserves full credit for the original foundation; the Obsidian design, telemetry layout, wallpaper system, Target workflow changes and ongoing reliability roadmap are specific to this fork.
