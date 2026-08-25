Status: implementation baseline complete. Bare-metal preflight, power-supply detection, dynamic display/hotplug validation, and the first full interactive V1 installation have passed on Lenovo 83F5. BSPWM session validation and VM validation remain pending.

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

Pending before merge:
- pre-logout post-install sanity check
- BSPWM login/session validation
- Polybar, Rofi, Kitty, Picom, Flameshot, audio, brightness, battery and telemetry validation
- suspend/resume validation
- rollback exercise
- VMware guest validation
- optional VirtualBox/KVM smoke validation where available
