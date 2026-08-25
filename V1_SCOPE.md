# KaliPWM roadmap

## V1 — Obsidian Tactical desktop

V1 is the adaptive BSPWM desktop release. Scope is intentionally frozen around:

- safe installer, pre-flight, backup and rollback
- bare-metal / VMware / VirtualBox / KVM environment handling
- dynamic display topology and hotplug foundations
- automatic battery/backlight/network/VPN discovery
- volume and brightness keys
- Flameshot screenshots
- Vim and standard `cat`
- BSPWM / Polybar / Kitty / Picom / Rofi visual redesign
- operator target state and optional hardware telemetry
- XFCE retained as fallback during validation

V1 must be validated on bare metal and at least one VM before merging to `main`.

## V2 — Login experience

V2 starts only after V1 is considered stable. It will rework the Kali graphical login/greeter and lock-screen experience to match Obsidian Tactical, including HiDPI and multi-monitor behavior and a safe route back to the stock Kali greeter.

Plymouth/LUKS boot presentation is a separate concern and must never hide or weaken the disk-unlock experience.
