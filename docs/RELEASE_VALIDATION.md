# KaliPWM v1.0 release validation

This document records the validation used to approve the first KaliPWM Obsidian public release.

The matrix is capability-based rather than machine-count-based: one validation host may satisfy several rows. Unsupported hardware is not a release failure; KaliPWM should report unavailable capabilities cleanly instead of inventing broken telemetry.

## Release candidate

- Release candidate source: `main`
- Validated code commit: `df258a954e67917b286cd36320fb5ffb11067e44`
- Validation date: 2026-08-28
- Final clean-install environment: current Kali GNU/Linux Rolling in VMware

## Final matrix

| Validation axis | State | Result |
|---|---|---|
| Installation | Clean Kali VM fresh clone/install from `main` | ✅ PASS |
| Installation | Primary bare-metal Kali host | ✅ PASS across Phase 3–7 regression work |
| Display | Standard/single display | ✅ PASS |
| Display | Multi-monitor/two-output | ⚠️ v1.0 proved two connected outputs; active external-output behavior was not proven until the 2026-09-30 post-release regression below |
| VPN | Disconnected | ✅ PASS |
| VPN | Connected | ⚪ Not exercised for v1.0; VPN detection/control had earlier live validation and remains capability-based |
| Power | Battery-present | ✅ PASS |
| Power | No-battery environment | ⚪ Not exercised for v1.0; absence is handled as an optional capability |
| Screenshots | Flameshot on BSPWM/X11 | ✅ PASS |
| Control Center | Rofi Control Center | ✅ PASS |
| Desktop chrome | Obsidian violet BSPWM borders | ✅ PASS |
| Diagnostics | `kalipwm doctor` | ✅ `0 FAIL` |
| Release checker | `kalipwm-release-check` | ✅ `0 failures`, `0 warnings` |
| Repository state | `main`, clean working tree | ✅ PASS |

## 2026-09-30 multi-monitor validation correction

The original v1.0 two-output check counted XRandR outputs reported as `connected`. That was useful hardware-detection coverage, but it did not prove that every connected output had active geometry or was usable by BSPWM. On the primary bare-metal host, the external HDMI display could be detected while remaining inactive.

The post-release multi-monitor regression for PR #15 closes that validation gap:

- XRandR exposed two providers: `modesetting` and `NVIDIA-G0`;
- `eDP-1` remained the primary internal display at `2560x1600+0+0`;
- `HDMI-1-0` was detected and activated at `2560x1440+2560+0`;
- BSPWM exposed both monitor names;
- workspaces `I`–`V` were assigned to `eDP-1` and `VI`–`X` to `HDMI-1-0`;
- Obsidian v2 launched one Polybar instance for each active monitor;
- a full reboot reproduced the layout automatically after login.
- a mid-session watcher was validated against delayed hybrid-GPU hot-plug transitions;
- while HDMI was physically unplugged and XRandR had settled to `disconnected`, BSPWM settled to the internal `eDP-1` monitor only;
- after reconnect, XRandR re-exposed `HDMI-1-0` as connected/active and BSPWM restored the external monitor automatically without a Control Center action or manual `xrandr`;
- the tested NVIDIA provider did not expose the external connector through the same `/sys/class/drm/card0-*` path as the integrated outputs, so XRandR's current output state is the practical runtime source used by KaliPWM for BSPWM display availability.

The display-manager login greeter is intentionally outside this BSPWM runtime validation. On the tested host the external monitor remained inactive at the greeter and was activated when the KaliPWM BSPWM session started.

Hot-plug timing is provider-dependent rather than instantaneous. During repeated tests the NVIDIA-backed HDMI output took several seconds to publish disconnect/reconnect state, and one source test began with the cable physically inserted while XRandR still reported `HDMI-1-0 disconnected`. KaliPWM intentionally waits for the usable XRandR topology instead of inferring display availability from physical cable presence alone.

This correction does not change the historical v1.0 tag. It documents the distinction between **connected** and **active** outputs and the later runtime fix that makes the external display usable.

## Final clean-install proof

A brand-new Kali VM was checked before installation and had:

```text
[OK] no KaliPWM checkout
[OK] no Polybar config
[OK] no BSPWM config
[OK] kalipwm not installed
```

The VM then cloned the public default branch normally:

```bash
git clone https://github.com/daviosardinha/kalipwm.git ~/kalipwm
cd ~/kalipwm
bash kalipwm.sh
```

After installation and reboot into BSPWM, the final validation returned:

```text
kalipwm doctor
19 OK | 0 WARN | 0 FAIL | 9 INFO

Release check
0 failure(s), 0 warning(s)
Release validation: PASS

Branch
main

Commit
df258a954e67917b286cd36320fb5ffb11067e44

Working tree
clean
```

## Interactive regression pass

The final clean-install VM was used to exercise the desktop rather than relying only on static CI checks.

Validated behavior:

- BSPWM starts normally after a fresh install and reboot;
- Obsidian v2 Polybar starts correctly;
- `Super + D` remains the application launcher;
- `Super + Space` opens the KaliPWM Control Center;
- System Summary opens as a dedicated floating Kitty/Fastfetch window;
- Flameshot screenshot selection works on the current Kali/Flameshot 14 BSPWM/X11 stack;
- the managed Flameshot helper enables the validated legacy X11 capture path where required;
- Obsidian violet BSPWM window borders render correctly;
- Target, wallpaper, diagnostics and system-management surfaces remain available;
- `kalipwm doctor` returns no failures;
- the release checker returns PASS.

## Bare-metal coverage

Phase 7 release checks on the primary bare-metal Kali host returned zero failures and zero warnings for both a single native display and a two-output multi-monitor state.

Earlier live regression work on the same host validated the hardware-sensitive paths that a VMware guest cannot meaningfully prove, including:

- physical F5/F6 brightness behavior through the validated `kalipwm-brightness` architecture;
- Control Center brightness delegation to the same helper;
- audio volume/mute;
- GPU and fan adaptive Polybar telemetry;
- battery/AC state;
- wallpaper, Target, screenshots, diagnostics, backup/rollback/update/repair behavior;
- preservation of the host display layout and avoidance of VMware-only startup behavior.

## Known v1.0 validation limits

Two capability states were deliberately not manufactured solely to satisfy the matrix:

1. **VPN connected during the final Phase 7 matrix.** The primary host's previous VPN setup had intentionally been disabled, so it was not re-enabled just for release testing. VPN-connected behavior had already been exercised earlier in development and the implementation remains interface/capability based.
2. **A truly battery-less final VM.** The VMware guest exposed a virtual battery. KaliPWM treats battery, GPU and fan telemetry as optional capabilities, and unavailable telemetry is not considered a failure.

These are documented validation gaps, not known functional breakages.

## CI gates

The release candidate passed the repository quality gates on `main`, including:

- maintained shell syntax;
- ShellCheck;
- F5/F6 brightness architecture regression;
- installer failure-handling regression;
- dependency-lock validation;
- Flameshot BSPWM/X11 regression;
- Release Quality repository self-check.

## Release decision

KaliPWM Obsidian v1.0 is approved for tagging.

The public release should point at the release-finalization commit derived from the validated `main` candidate above. Release-finalization changes are documentation-only and do not modify the validated installer or desktop runtime.
