Status: implementation baseline complete; bare-metal preflight and display hotplug validation passed on Lenovo 83F5. First full-install attempt exposed Kali rolling package-name drift before any theme configuration was applied; resolver fix is committed and CI is green. Full BSPWM installation/session validation and VM validation remain pending.

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
- failed installs now preserve and report the pre-install backup and leave an install-in-progress marker until success/rollback

Pending before merge:
- rerun full interactive installation on bare metal with the package resolver fix
- BSPWM login/session validation
- Polybar, Rofi, Kitty, Picom, Flameshot, audio, brightness, battery and telemetry validation
- rollback exercise
- VMware guest validation
- optional VirtualBox/KVM smoke validation where available
