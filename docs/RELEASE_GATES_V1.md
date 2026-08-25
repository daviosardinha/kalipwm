# V1 merge gates

V1 can merge to `main` only after:

1. static checks pass
2. bare-metal pre-flight reports correct environment and hardware
3. BSPWM session works on the primary bare-metal validation machine
4. VMware Workstation host remains unaffected on bare metal
5. physical external-display hotplug is validated without hard-coded connector names or GPU-provider routing
6. at least one VM environment completes install, BSPWM session, dynamic display, rerun/idempotency, and trusted uninstall validation
7. VMware Kali guest install/session validation is completed before declaring VMware support validated
8. rollback is exercised at least once
9. no critical regression remains in Polybar, Kitty, Picom, Rofi, sxhkd, Flameshot, audio/brightness OSD, power menu, or display watcher

Current status:

- gates 1-6 and 8-9: passed on the V1 branch
- KVM/QEMU guest validation: passed on a Proxmox Kali guest
- VMware guest validation: pending
- VirtualBox guest validation: optional smoke test if an environment is available
