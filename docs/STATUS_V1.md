Status: implementation baseline complete; bare-metal preflight and display hotplug validation passed on Lenovo 83F5. Full BSPWM installation/session validation and VM validation remain pending.

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

Pending before merge:
- full interactive installation on bare metal
- BSPWM login/session validation
- Polybar, Rofi, Kitty, Picom, Flameshot, audio, brightness, battery and telemetry validation
- rollback exercise
- VMware guest validation
- optional VirtualBox/KVM smoke validation where available
