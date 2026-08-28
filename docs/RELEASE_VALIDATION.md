# KaliPWM v1.0 release validation

This document tracks the final validation required before tagging `v1.0.0`.

The matrix is deliberately capability-based rather than machine-count-based. One validation host may satisfy several rows at once; the goal is to exercise each environment class without pretending every combination requires a separate installation.

## Minimum matrix

| Validation axis | Required state | Status |
|---|---|---|
| Installation | Clean Kali VM fresh install | ⏳ Pending |
| Installation | Primary bare-metal Kali host validation | ⏳ Pending |
| Display | Standard/single-display geometry | ⏳ Pending |
| Display | Ultrawide or multi-monitor geometry where available | ⏳ Pending |
| VPN | Tunnel connected | ⏳ Pending |
| VPN | Tunnel disconnected | ⏳ Pending |
| Power | Battery-present hardware | ⏳ Pending |
| Power | No-battery environment | ⏳ Pending |

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

## Release gate

`v1.0.0` can be tagged only when:

1. every minimum matrix capability above is either validated or explicitly documented as unavailable for testing;
2. fresh-install validation has passed on at least one clean Kali VM;
3. the primary bare-metal environment has passed the final regression run;
4. the repository release self-check and normal CI gates are green;
5. README, ROADMAP, CHANGELOG, supported/tested environments, known limitations and migration notes describe the same behavior that exists on `main`.
