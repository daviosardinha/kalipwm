# Manual fixes migrated into V1

The following recurring post-install tasks are now part of the V1 design and should no longer require editing host-specific values by hand.

| Previous manual task | V1 implementation |
|---|---|
| Discover battery / adapter and edit Polybar | installer discovers power-supply devices; `kalipwm-battery` reads the detected battery dynamically |
| Add `battery` to Polybar | battery status module is included by default and renders nothing when no battery exists |
| Install/configure brightness keys | `brightnessctl` is installed when available and XF86 brightness bindings are included |
| Configure volume sink `0` | `kalipwm-audio` controls the current default PipeWire/PulseAudio sink |
| Hard-code `eth0`, `wlan0`, `tun0` | network/VPN helpers discover active interfaces dynamically |
| Edit Polybar after interface changes | no interface name is required in Polybar configuration |
| Install/configure screenshot utility | Flameshot is installed and bound to Print/Shift+Print/Ctrl+Print |
| Restart sxhkd manually after install | installer signals an existing sxhkd process; new BSPWM sessions load the config normally |
| Force VMware `Virtual1` to 1920x1080 | removed; `kalipwm-display` uses the actual XRandR topology |
| Run VMware guest wrapper everywhere | wrapper is conditional on the VMware guest profile |
| Replace `cat` with batcat | removed; standard `cat` is preserved |
| Replace Vim with Neovim | removed; Vim is installed and preserved |
