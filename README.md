# KaliPWM — Obsidian Tactical V1

An adaptive Kali Linux BSPWM environment based on the original [afsh4ck/kalipwm](https://github.com/afsh4ck/kalipwm), reworked for current Kali systems, bare-metal laptops/workstations, and common virtual-machine guests.

> V1 is under active validation. Keep your existing XFCE session available as a fallback until your hardware has been tested.

## V1 goals

V1 keeps the useful KaliPWM foundation — BSPWM, Polybar, Kitty, Picom, Rofi, ZSH/Powerlevel10k and tmux — while removing hardware assumptions and repetitive post-install fixes.

### Adaptive environment detection

The installer detects the current virtualization environment with `systemd-detect-virt`, shows the result, and asks the user to confirm or override it.

Supported V1 profiles:

- Bare metal
- VMware guest
- VirtualBox guest
- KVM/QEMU guest

VMware guest tools are installed and `vmware-user-suid-wrapper` is launched **only inside a VMware guest**. A bare-metal machine running VMware Workstation is not treated as a VMware guest.

### Safe installation

Before replacing managed dotfiles, V1 creates a timestamped backup under:

```text
~/.local/state/kalipwm/backups/
```

Restore the newest backup with:

```bash
bash kalipwm.sh --rollback
```

`--uninstall` currently performs the same configuration rollback. Packages installed through APT are intentionally not automatically removed.

### Hardware-aware configuration

The installer detects, where available:

- battery and AC adapter names
- backlight device
- Wi-Fi interface
- Ethernet interface
- internal laptop display
- connected XRandR outputs
- platform/vendor information

The generated profile is stored in:

```text
~/.config/kalipwm/profile.conf
```

No `BAT0`, `ADP1`, `wlan0`, `eth0`, `tun0`, `Virtual1`, or `1920x1080` value is required by the V1 desktop configuration.

### Dynamic displays

`kalipwm-display` applies the detected display topology and watches for XRandR hotplug changes.

On bare metal, an internal `eDP`/`LVDS` panel is preferred as the primary display. External outputs can be positioned right, left, above, below, or mirrored. VMware/VirtualBox/KVM guests use automatic virtual-display sizing instead of a physical-monitor layout.

HDMI/DisplayPort/USB-C behavior still needs to be validated on each physical GPU/port topology before being considered fully hardware-certified.

### Automatic fixes incorporated from repeated KaliPWM setup work

V1 replaces the old manual configuration steps for:

- battery module names
- brightness keys
- volume keys
- Wi-Fi/Ethernet IP display
- VPN interface display
- screenshot bindings
- Polybar/SXHKD reloads after setup

Hardware data shown by Polybar is generated dynamically rather than by editing `modules.ini` after each installation.

## Obsidian Tactical visual system

V1 uses a deliberately restrained operator-workstation design:

- charcoal/graphite surfaces
- violet as the primary interaction accent
- green for healthy/connected state
- amber for attention
- red for targets/critical state
- 9px Picom corners
- subtle shadows and blur
- readable Kitty opacity instead of highly transparent terminals
- thin active BSPWM borders
- centered Spotlight-style Rofi launcher

Polybar is designed around operational context instead of decorative widgets. Depending on the hardware it can show the current target, platform power profile, CPU/GPU/fan telemetry, active network IP, VPN status, battery and time.

## Command preferences

V1 deliberately preserves normal Unix/editor behavior:

```text
cat  -> standard cat
vim  -> Vim
```

Neovim is not installed by KaliPWM V1 and `vim` is not aliased to `nvim`. `batcat` and `lsd` may be installed as optional utilities, but they do not replace `cat` or `ls`.

## Screenshots

Flameshot is the screenshot application.

```text
Print         Flameshot interactive GUI
Shift+Print   Full screenshot -> ~/Pictures/Screenshots
Ctrl+Print    Flameshot launcher
```

## Installation — development branch

Clone the fork and switch to the V1 branch:

```bash
git clone https://github.com/daviosardinha/kalipwm.git
cd kalipwm
git switch v1/obsidian-tactical
```

Run detection only first:

```bash
bash kalipwm.sh --preflight
```

If the detection looks correct:

```bash
bash kalipwm.sh
```

After installation, log out and select **BSPWM** from the login session chooser. Keep XFCE available while V1 is being validated.

## Main shortcuts

| Shortcut | Action |
|---|---|
| `Super + Enter` | Kitty |
| `Super + D` | Rofi application launcher |
| `Super + 1..5` | Switch workspace |
| `Super + Shift + 1..5` | Move window to workspace |
| `Super + Arrow` | Focus tiled window |
| `Super + Shift + Arrow` | Swap tiled window |
| `Super + Alt + Arrow` | Resize window |
| `Super + Shift + F` | Firefox |
| `Super + Shift + B` | Burp Suite |
| `Super + Shift + A` | Thunar |
| `Print` | Flameshot GUI |
| `Super + Alt + R` | Restart BSPWM |

Set an operational target with:

```bash
target 10.10.11.42
```

Clear it with:

```bash
target reset
```

## Pre-flight / recovery

Detection without installation:

```bash
bash kalipwm.sh --preflight
```

Rollback:

```bash
bash kalipwm.sh --rollback
```

## V2

V2 is intentionally outside the V1 scope. Once the desktop and installer are stable, V2 will address the Kali graphical login/greeter and lock-screen experience so it can visually match Obsidian Tactical without mixing authentication-layer changes into the desktop rollout.

## Credits

KaliPWM was originally created by **afsh4ck**. This fork preserves that foundation and MIT licensing while adding the adaptive installer, hardware/environment handling, compatibility work and Obsidian Tactical V1 redesign.
