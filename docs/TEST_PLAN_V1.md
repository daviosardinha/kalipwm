# V1 validation plan

Run tests in this order. Do not merge V1 to `main` until the relevant sections pass.

## 1. Read-only pre-flight

```bash
bash kalipwm.sh --preflight
```

Confirm environment, platform, battery, backlight, network interfaces and display names are correct.

## 2. Bare-metal install

Run:

```bash
bash kalipwm.sh
```

Log out, select BSPWM, and log in. Keep XFCE available as a fallback.

Validate:

- Polybar starts on the expected monitor(s)
- Kitty opens with `Super+Enter`
- Rofi opens with `Super+D`
- Vim launches as `vim`
- `cat` is standard cat
- Flameshot works on Print
- brightness keys work where a backlight exists
- volume keys control the current default sink
- target state updates after `target <IP>`
- network and VPN state update dynamically
- battery widget appears only where a battery exists
- Picom renders without compositor errors

## 3. Bare-metal display hotplug

With BSPWM active:

1. connect HDMI
2. confirm external monitor is detected and arranged according to `external_position`
3. disconnect HDMI and confirm the internal panel remains usable
4. repeat with USB-C/DisplayPort if available
5. inspect `xrandr --listproviders` and confirm the script did not overwrite PRIME provider routing

## 4. VMware host safety

On a bare-metal system that has VMware Workstation installed:

- `systemd-detect-virt` must report `none`
- installer must select `baremetal`
- `open-vm-tools` guest integration must not be required by the profile
- BSPWM must not launch `vmware-user-suid-wrapper`
- VMware host services/modules should continue working independently

## 5. VMware guest install

Inside a Kali VMware guest:

- `systemd-detect-virt` should report `vmware`
- installer should select VMware guest
- open-vm-tools guest packages should be installed when available
- BSPWM should launch VMware desktop integration
- clipboard integration should work
- virtual display resizing should remain automatic
- no physical-output names or 1920x1080 mode should be forced

## 6. Rollback

Run:

```bash
bash kalipwm.sh --rollback
```

Confirm the previous managed dotfiles and login shell are restored. Packages installed by APT are intentionally left installed.
