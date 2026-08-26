# V1 known limitations before hardware validation

- Display hotplug logic is implemented but has not yet been validated against the Lenovo Legion physical HDMI/USB-C port routing.
- Multi-monitor workspace redistribution is initialized at BSPWM startup; post-login monitor hotplug may need an additional workspace rebalance pass after real hardware testing.
- **Suspend/resume external-display regression:** after the laptop resumes from sleep, an external HDMI display can remain black even though XRandR still reports `HDMI-1-0 connected` and BSPWM still retains the monitor. Unplug/replug does not recover it. This needs a dedicated resume/link-retrain health-reconciliation fix; logging out must not be the required recovery path.
- **Polybar VPN false-OFF regression:** an active Ronin66 lab VPN can still render `VPN ○ OFF`. The current detector only checks `tun*`, `tap*`, and `wg*` interfaces with an IPv4 address, which is too narrow for all VPN implementations. Follow-up should use generic route/link/address and, where useful, NetworkManager VPN state without hard-coding one lab/client.
- VirtualBox and KVM package profiles are implemented defensively but need live guest validation.
- GitHub Actions may require Actions to be enabled on the newly created fork before the static workflow runs.
- V1 does not modify the Kali graphical greeter/login design. That work is reserved for V2.
- V1 does not automatically remove APT packages during rollback/uninstall; it restores managed configuration and the previous login shell.
