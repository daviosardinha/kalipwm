# V1 implementation checklist

## Implemented in the initial V1 branch

- [x] Legacy `kalipwm.sh` entrypoint preserved
- [x] New adaptive `install.sh`
- [x] `--preflight`, `--rollback`, `--uninstall`
- [x] Timestamped dotfile backup
- [x] Environment detection and confirmation
- [x] Conditional VMware/VirtualBox/KVM guest packages
- [x] No bare-metal VMware guest wrapper
- [x] No hard-coded `Virtual1` / 1920x1080
- [x] Dynamic XRandR display helper and hotplug watcher
- [x] Automatic battery, adapter, backlight and interface discovery
- [x] Dynamic Polybar network/VPN/battery/profile/telemetry modules
- [x] PipeWire/PulseAudio default-sink volume helper
- [x] Brightness keys
- [x] Flameshot key bindings
- [x] Standard `cat`
- [x] Vim instead of Neovim
- [x] Distro Kitty / Polybar / Picom packages instead of duplicate source installs
- [x] Obsidian Tactical Polybar palette/layout
- [x] Obsidian Tactical Kitty palette
- [x] Obsidian Tactical Picom geometry
- [x] Obsidian Tactical Rofi launcher
- [x] PolicyKit / NetworkManager / Dunst / power-manager BSPWM session bootstrap
- [x] XFCE left untouched as fallback
- [x] Static CI guard added

## Validation still required before V1 merge

- [ ] Run `--preflight` on Lenovo Legion bare metal
- [ ] Install and log into BSPWM on Lenovo Legion
- [ ] Validate Intel/NVIDIA hybrid desktop behavior
- [ ] Validate HDMI hotplug
- [ ] Validate USB-C/DisplayPort hotplug if available
- [ ] Validate multi-monitor workspace distribution after hotplug
- [ ] Validate Flameshot shortcuts
- [ ] Validate brightness/media keys
- [ ] Validate Polybar battery/network/VPN/telemetry values
- [ ] Validate VMware Workstation host remains untouched on bare metal
- [ ] Validate installer inside VMware Kali guest
- [ ] Validate VMware clipboard/dynamic display integration
- [ ] Validate rollback from both bare metal and VM installs
- [ ] Review Rofi power-menu styling
- [ ] Enable/confirm GitHub Actions execution on the fork

V1 should not be merged to `main` until the relevant checks above pass.
