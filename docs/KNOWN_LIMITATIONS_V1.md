# V1 known limitations before hardware validation

- Display hotplug logic is implemented but has not yet been validated against the Lenovo Legion physical HDMI/USB-C port routing.
- Multi-monitor workspace redistribution is initialized at BSPWM startup; post-login monitor hotplug may need an additional workspace rebalance pass after real hardware testing.
- VirtualBox and KVM package profiles are implemented defensively but need live guest validation.
- GitHub Actions may require Actions to be enabled on the newly created fork before the static workflow runs.
- V1 does not modify the Kali graphical greeter/login design. That work is reserved for V2.
- V1 does not automatically remove APT packages during rollback/uninstall; it restores managed configuration and the previous login shell.
