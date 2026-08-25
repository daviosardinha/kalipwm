# V1 merge gates

V1 can merge to `main` only after:

1. static checks pass
2. bare-metal pre-flight reports correct environment and hardware
3. BSPWM session works on the primary bare-metal validation machine
4. VMware Workstation host remains unaffected on bare metal
5. HDMI hotplug is validated
6. VMware Kali guest install is validated
7. rollback is exercised at least once
8. no critical regression remains in Polybar, Kitty, Picom, Rofi, sxhkd or Flameshot
