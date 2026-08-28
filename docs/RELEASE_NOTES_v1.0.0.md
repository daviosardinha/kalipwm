# KaliPWM Obsidian v1.0.0

KaliPWM Obsidian v1.0.0 is the first public release of the fork as a repeatable, keyboard-driven Kali Linux workstation layer for offensive-security labs, CTFs, research and daily security work.

## Highlights

- Obsidian BSPWM desktop with Roman-numeral workspaces and violet active-window chrome.
- Obsidian v2 Polybar with adaptive network, VPN, Target, CPU/GPU, fan, RAM, audio, power and clock telemetry.
- Rofi-based KaliPWM Control Center on `Super + Space`.
- Persistent Target and wallpaper workflows.
- Flameshot screenshot workflow hardened for current BSPWM/X11 environments.
- `kalipwm doctor` for read-only diagnostics.
- `kalipwm update` for fast managed-file updates without reinstalling the toolchain.
- `kalipwm repair` and `--dry-run` for controlled managed-state recovery.
- Timestamped `kalipwm backup`, `backups` and `rollback` workflows.
- Hardware/VM-aware startup that preserves X display geometry and only enables VMware-specific desktop integration when VMware is detected.
- Hardware-adaptive GPU/fan Polybar modules.
- Reproducible fresh-install dependency pins and SHA-256 verification for the pinned Kitty bundle.
- Fail-fast installer reporting with explicit recovery guidance.
- CI regression coverage for shell quality, F5/F6 brightness behavior, installer failures, dependency locking and Flameshot X11 capture behavior.

## Installation

Start from a clean Kali installation where possible and run the installer as the normal desktop user:

```bash
git clone https://github.com/daviosardinha/kalipwm.git ~/kalipwm
cd ~/kalipwm
bash kalipwm.sh
sudo reboot
```

After reboot, select the **BSPWM** session from the login screen.

Do not run `kalipwm.sh` itself with `sudo`; the installer requests elevation only for operations that require it.

## Tested environments

v1.0 was validated across:

- current Kali GNU/Linux Rolling;
- a completely fresh VMware Kali installation cloned from public `main`;
- the primary bare-metal Kali laptop;
- single-display operation;
- a two-output multi-monitor state;
- battery-present hardware;
- VMware graphics/session integration;
- physical laptop brightness keys on supported bare-metal hardware;
- optional GPU and fan telemetry on supported bare-metal hardware.

The final clean VMware installation completed with:

```text
kalipwm doctor: 19 OK | 0 WARN | 0 FAIL | 9 INFO
release check: 0 failures, 0 warnings, PASS
```

## Known limitations

- The final Phase 7 matrix did not reconnect the primary host's intentionally disabled VPN solely to manufacture a `vpn-connected` result. VPN-connected behavior had already been exercised during earlier development and remains capability/interface based.
- The final VMware guest exposed a virtual battery, so a truly battery-less v1.0 release candidate was not available. Battery, GPU and fan telemetry are optional capabilities and are omitted/reported informationally when unavailable.
- Flameshot 14 on minimal X11 window managers can prefer the desktop portal capture path, which may time out under BSPWM. KaliPWM explicitly enables Flameshot's validated legacy X11 capture path for the managed BSPWM workflow.
- Hardware brightness controls require a supported backlight device. The validated bare-metal F5/F6 path is intentionally preserved rather than replaced with a generic assumption.
- Polybar click-to-open Control Center integration is intentionally not part of the design; Polybar remains a compact display surface.

## Updating an existing KaliPWM installation

For a working Git-based KaliPWM installation:

```bash
kalipwm update
```

The update command requires a clean checkout, creates a `pre-update` managed-configuration snapshot, fast-forwards to `origin/main`, and refreshes KaliPWM-managed files without rerunning the full package/toolchain installer.

Before an update or manual migration, creating an explicit backup is also recommended:

```bash
kalipwm backup --label before-v1
```

## Migration notes for older builds

Older KaliPWM/Obsidian test builds may contain local configuration that predates the current managed layout.

Recommended migration flow:

```bash
cd ~/kalipwm
git status --short
kalipwm backup --label before-v1
kalipwm update
kalipwm doctor
```

If `kalipwm update` refuses because the checkout is dirty, review and preserve those changes rather than forcing the update.

If managed configuration has drifted or older helper symlinks remain, inspect the repair plan first:

```bash
kalipwm repair --dry-run
```

Then apply only when the plan is expected:

```bash
kalipwm repair
```

KaliPWM intentionally avoids resetting existing working third-party Git checkouts merely to match the fresh-install dependency lock.

## Recovery

Useful recovery commands:

```bash
kalipwm doctor
kalipwm backups
kalipwm rollback latest --dry-run
kalipwm rollback latest
```

A real rollback creates a `pre-rollback` safety snapshot before restoring the requested managed state.

## Release validation

The detailed v1.0 validation record is maintained in [`RELEASE_VALIDATION.md`](RELEASE_VALIDATION.md).

The release candidate was installed from scratch from the public default branch and manually exercised for BSPWM startup, Polybar, Control Center, System Summary, screenshots, wallpapers, window borders and diagnostics before release approval.

## Credits

KaliPWM Obsidian remains a fork and modified continuation of the original KaliPWN/KaliPWM project by **afsh4ck**. The upstream project is credited for the original foundation; the Obsidian design, adaptive telemetry, management workflows, release hardening and ongoing development are specific to this fork.
