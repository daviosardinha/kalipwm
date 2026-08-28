# KaliPWM v1.0 release validation

This document tracks the final validation required before tagging `v1.0.0`.

The matrix is deliberately capability-based rather than machine-count-based. One validation host may satisfy several rows at once; the goal is to exercise each environment class without pretending every combination requires a separate installation.

## Minimum matrix

| Validation axis | Required state | Status |
|---|---|---|
| Installation | Clean Kali VM fresh install | ⏳ Pending |
| Installation | Primary bare-metal Kali host validation | 🟡 Release baseline PASS; final interactive pass before tag |
| Display | Standard/single-display geometry | ✅ 2560x1600 bare-metal baseline |
| Display | Ultrawide or multi-monitor geometry where available | ✅ Two-output bare-metal validation |
| VPN | Tunnel connected | ⏳ Pending; may be validated in clean VM with a temporary tunnel |
| VPN | Tunnel disconnected | ✅ Bare-metal baseline |
| Power | Battery-present hardware | ✅ Bare-metal baseline |
| Power | No-battery environment | ⏳ Pending |

## Clean Kali VM fresh-install procedure

Use a separate disposable VM. Do not perform this fresh-install test on the already validated bare-metal host.

Recommended baseline:

- current Kali Rolling installation;
- default graphical desktop available before KaliPWM installation;
- 2 or more vCPUs;
- 4 GiB or more RAM;
- 40 GiB or more disk;
- one standard virtual display for the initial install test;
- no previous KaliPWM checkout, managed configuration or KaliPWM backup restored into the VM.

After the first normal Kali login, take a hypervisor snapshot such as `clean-kali-pre-kalipwm`. Do not preinstall KaliPWM dependencies: the release test is intended to exercise the installer itself.

If `git` is already present, clone the release-quality branch directly:

```bash
git clone --branch feature/public-release-quality --single-branch https://github.com/daviosardinha/kalipwm.git ~/kalipwm
cd ~/kalipwm
git rev-parse --short=12 HEAD
bash kalipwm.sh
```

If the clean image does not contain `git`, install only Git first and then run the commands above:

```bash
sudo apt update
sudo apt install -y git
```

A successful installer run must reach the KaliPWM deployment-complete message without an unexpected failure summary. Reboot afterward:

```bash
sudo reboot
```

At the login screen select the BSPWM session. After the desktop starts, run:

```bash
cd ~/kalipwm
bash SCRIPTS/kalipwm-release-check
bash SCRIPTS/kalipwm-release-check --markdown
kalipwm doctor
```

Keep the VM intact after this test. The same fresh-install VM can be used for the no-battery capability and temporary `vpn-connected` validation before it is discarded.

## Post-install release check

After installation and reboot into BSPWM, run the read-only release check from the same checkout being validated:

```bash
bash SCRIPTS/kalipwm-release-check
```

The check reports only release-relevant environment classes and managed-state health. It does not change configuration and does not print IP addresses, Target state, usernames or hostnames.

To produce a sanitized row suitable for this validation document:

```bash
bash SCRIPTS/kalipwm-release-check --markdown
```

A release candidate is not considered validated merely because the script returns `PASS`. The relevant interactive behavior must also be exercised on the host.

## Interactive regression pass

For each fresh-install environment where the feature is applicable, validate:

- BSPWM session starts normally and keeps the display geometry supplied by X;
- Obsidian v2 Polybar starts with no dead optional telemetry blocks;
- `Super + D` opens the normal Rofi launcher;
- `Super + Space` opens the KaliPWM Control Center;
- `kalipwm doctor` finishes with no `FAIL` findings;
- Target set/read/reset works without depending on VPN state;
- VPN connected/disconnected presentation follows the actual tunnel state;
- screenshot region selection opens Flameshot;
- wallpaper switching works and persists after BSPWM restart;
- volume/mute works on supported hardware;
- physical brightness F5/F6 and Control Center brightness use the validated KaliPWM brightness helper on backlight-capable hardware;
- `kalipwm backup`, `kalipwm repair --dry-run` and rollback dry-run remain available;
- reboot restores the same working desktop state.

Unsupported hardware is not a release failure. For example, a VM with no battery or backlight should report those capabilities as absent rather than fabricate a broken module.

## Validation records

Sanitized `--markdown` rows go here. Do not add hostnames, usernames, IP addresses, VPN endpoint addresses, Target values or other engagement-specific data.

| Date | Commit | Environment | Display | VPN | Power | Doctor | Control Center | Result |
|---|---|---|---|---|---|---|---|---|
| 2026-08-28 | `cafb269415c7` | bare-metal | single:standard:2560x1600 | vpn-disconnected | battery-present | pass | installed | PASS |
| 2026-08-28 | `b767e730a089` | bare-metal | multi-monitor:2-outputs:first-2560x1600 | vpn-disconnected | battery-present | pass | installed | PASS |

### Primary bare-metal baseline

The first Phase 7 release check passed with zero failures and zero warnings on the primary bare-metal Kali host. This covers the standard single-display, VPN-disconnected and battery-present matrix states. A second zero-failure/zero-warning pass covered a two-output multi-monitor state. The desktop runtime itself was not modified by the Phase 7 validation tooling; a final interactive regression pass is still required before the release tag.

The primary host does not need to re-enable a previously disabled VPN solely for release testing. The remaining `vpn-connected` capability can be exercised later on the clean Kali VM with a temporary test tunnel, keeping the bare-metal host unchanged.

## Release gate

`v1.0.0` can be tagged only when:

1. every minimum matrix capability above is either validated or explicitly documented as unavailable for testing;
2. fresh-install validation has passed on at least one clean Kali VM;
3. the primary bare-metal environment has passed the final regression run;
4. the repository release self-check and normal CI gates are green;
5. README, ROADMAP, CHANGELOG, supported/tested environments, known limitations and migration notes describe the same behavior that exists on `main`.