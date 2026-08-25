Status: implementation baseline complete. Bare-metal preflight, power-supply detection, dynamic display/hotplug validation, the first full interactive V1 installation, pre-login sanity check, and first BSPWM login have passed on Lenovo 83F5. BSPWM application/session QA is in progress; VM validation remains pending.

Validated on bare metal:
- Kali GNU/Linux Rolling detected correctly
- environment detected as baremetal
- internal battery detection selects BAT0 and ignores peripheral scope=Device battery-class devices
- mains adapter detection selects ADP0
- backlight detected as intel_backlight
- Wi-Fi detected as wlan0
- Ethernet detected as eth0
- internal display detected as eDP-1
- external display dynamically detected as DP-1 when connected
- external display placement to the right works as intended
- disconnect/reconnect hotplug behavior works as intended
- hybrid XRandR providers remain modesetting + NVIDIA-G0 without forcing NVIDIA desktop ownership
- static CI checks pass

Install regression found and fixed:
- first interactive install stopped at APT resolution because `network-manager-gnome` and `policykit-1-gnome` were visible in metadata but had no install candidate on the current Kali rolling snapshot
- installer now uses `network-manager-applet`, `nm-connection-editor`, and `mate-polkit`
- package availability now checks the actual APT Candidate value instead of `apt-cache show`
- BSPWM startup now recognizes the MATE PolicyKit authentication agent path used by current Kali
- failed installs preserve and report the pre-install backup and leave an install-in-progress marker until success/rollback

First successful full install:
- backup created before package/config changes
- installer resolved 41 packages with valid candidates and completed APT installation successfully
- BSPWM, sxhkd, Polybar, Picom, Rofi, Kitty, Flameshot, brightnessctl, dunst and supporting desktop packages installed
- Oh My Zsh, Powerlevel10k, zsh-autosuggestions and zsh-syntax-highlighting installed
- tmux configuration installed
- BSPWM desktop configuration installed
- generated profile records baremetal, BAT0, ADP0, intel_backlight, wlan0, eth0, eDP-1/DP-1 and external position right
- editor remains Vim and `cat` remains standard `/usr/bin/cat`
- current successful install backup: `/home/stark/.local/state/kalipwm/backups/20260825-114233`
- observed gedit schema override messages and dirsearch SyntaxWarning are package-side, non-fatal warnings; installation completed normally

Pre-login sanity validation:
- `/usr/share/xsessions/bspwm.desktop` is present
- bspwm, sxhkd, Polybar, Picom, Rofi, Kitty, Flameshot, brightnessctl and pactl resolve from PATH
- installed BSPWM and display helper Bash syntax passes
- battery helper reports the real BAT0
- network helper reports the active WLAN address
- VPN helper reports disconnected state cleanly
- telemetry reports CPU/GPU/fan values

Telemetry regression found and fixed before first BSPWM login:
- sanity output exposed that the telemetry helper called `nvidia-smi` whenever NVIDIA was installed
- because Polybar polled telemetry every 3 seconds, this could repeatedly wake a sleeping hybrid-laptop dGPU and waste battery
- telemetry now checks NVIDIA PCI runtime PM state first and only runs `nvidia-smi` if the dGPU is already active
- `KALIPWM_FORCE_GPU_TELEMETRY=1` provides an explicit override for systems without usable runtime-PM reporting
- telemetry polling interval increased from 3 seconds to 15 seconds
- static regression guards cover runtime-PM gating and polling interval

First BSPWM session:
- BSPWM login succeeds and the Obsidian Tactical desktop renders with Polybar and tiled applications
- Kitty launches and normal application use is possible in the session
- external monitor layout remains correct in-session

Flameshot regressions found and fixed during first BSPWM session:
- Flameshot 14 initially timed out waiting for the XDG Desktop Portal Screenshot interface under BSPWM (`Screenshot portal timed out after 30 seconds`)
- KaliPWM now ships `CONFIGS/config/flameshot/flameshot.ini` with `useX11LegacyScreenshot=true`, forcing Flameshot's native X11 capture path in the BSPWM session
- GUI capture is launched without `--path`, preserving normal Flameshot interactive behavior: `Ctrl+C` copies to clipboard without forcing a save
- `saveAfterCopy=false` is shipped so clipboard capture remains clipboard-only by default
- `Print` and `Ctrl+Print` both open Flameshot directly in capture mode; `Shift+Print` remains the explicit full-desktop save action
- live validation passed: capture overlay opens, screenshots work, and clipboard copy/paste behavior works as intended
- static CI guards the BSPWM/Flameshot behavior

Pending before merge:
- complete BSPWM application/session validation
- Polybar, Rofi, Kitty, Picom, audio, brightness, battery and telemetry validation
- suspend/resume validation
- rollback exercise
- VMware guest validation
- optional VirtualBox/KVM smoke validation where available
