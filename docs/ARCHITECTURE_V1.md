# V1 adaptive architecture

```text
install.sh
   |
   +-- pre-flight
   +-- systemd-detect-virt + user confirmation
   +-- hardware discovery
   +-- backup
   +-- environment-specific packages
   +-- common BSPWM stack
   +-- generated ~/.config/kalipwm/profile.conf
   |
   +--> BSPWM session
          |
          +-- VMware guest integration (VMware guests only)
          +-- kalipwm-display (dynamic XRandR topology)
          +-- sxhkd
          +-- PolicyKit agent
          +-- NetworkManager applet
          +-- Dunst
          +-- power manager
          +-- Picom
          +-- Polybar per connected monitor
                 |
                 +-- target.sh
                 +-- kalipwm-profile
                 +-- kalipwm-telemetry
                 +-- kalipwm-network
                 +-- kalipwm-vpn
                 +-- kalipwm-battery
```

The generated profile records detected device names but runtime helpers remain defensive and rediscover changing state where useful. The visual layer therefore does not need to embed interface, battery, adapter, thermal-zone, monitor, or VM output names.
