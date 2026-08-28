# Changelog

This changelog tracks user-visible changes that reach `main`.

The rule for this repository is simple: when a task is validated and merged into `main`, its documentation status must be updated in the same completion cycle. Experimental branch work is not recorded as stable functionality.

## Unreleased

No unreleased feature is considered stable until it reaches `main`.

Current development work is tracked in [`ROADMAP.md`](ROADMAP.md).

## 2026-08-28 — Rofi-based KaliPWM Control Center

### Added

- A dedicated KaliPWM Control Center on `Super + Space` while preserving `Super + D` as the normal Obsidian application launcher.
- Rofi sections for Network, VPN, Target, Wallpaper, Screenshot, Display, Audio, System, Diagnostics and Power.
- In-Rofi read-only reports for diagnostics and status views so routine checks do not spawn terminal windows.
- Background execution for configuration backups with completion notifications.

### Changed

- Control Center actions reuse existing KaliPWM helpers instead of duplicating Target, wallpaper, screenshot or system-management logic.
- Brightness actions use the validated `kalipwm-brightness` helper and OSD path previously proven on the primary bare-metal host, preserving the physical F5/F6 behavior.
- Interactive terminal applications such as `nmtui` may still open a terminal when their native workflow requires one.
- Polybar remains display-only; click-to-open Control Center actions were explicitly removed from the roadmap and are not planned.

### Validation

- `Super + Space` opened the Control Center correctly on the primary bare-metal Kali host.
- Display brightness actions and physical F5/F6 brightness keys passed after restoring the validated helper architecture.
- Audio volume and mute controls passed without regression.
- Diagnostics → `kalipwm doctor` remained inside Rofi.
- Network/VPN status, Target copy, wallpaper switching, screenshot region selection, backup/list-backups/repair-dry-run and power-menu cancellation all passed the final live regression pass.

## 2026-08-28 — Hardware-adaptive Obsidian v2 Polybar

### Changed

- Obsidian v2 now builds its right-side Polybar module list dynamically at launch instead of assuming optional telemetry is always present.
- GPU is included only when the existing GPU telemetry helper returns a real value.
- Fan is included only when readable hwmon fan telemetry exists.
- The fan block is now explicit and compact (`FAN <rpm>RPM`) and is positioned between GPU and RAM telemetry.
- `fan-compact.sh` reports the highest current readable fan speed and emits no `N/A` placeholder when telemetry is unavailable.
- The static fallback right-side ordering now matches the adaptive layout: CPU, GPU, fan, RAM, audio, power, time and system menu.

### Validation

- `bash -n CONFIGS/config/polybar/obsidian-v2/launch.sh` passed before deployment.
- The branch was deployed directly to the primary bare-metal Kali host and both GPU and fan modules were confirmed loaded by the Polybar log checks.
- `kalipwm doctor` confirmed battery, GPU and fan telemetry with `21 OK | 0 WARN | 0 FAIL | 7 INFO`.
- Live fan telemetry rendered correctly in Polybar and tracked the host sensors rather than showing a dead placeholder.
- A fresh reboot restored the adaptive layout successfully; post-reboot validation showed the fan block active at `FAN 2500RPM` alongside GPU, RAM, audio, power/battery and time.

## 2026-08-27 — Dynamic display and VMware-aware startup

### Changed

- Removed the legacy BSPWM startup command that forced `Virtual1` to `1920x1080`.
- BSPWM now leaves display output naming, active mode selection, dynamic resize behavior and multi-monitor state to the running X session instead of imposing one VM-specific mode.
- `vmware-user-suid-wrapper` is now guarded by `systemd-detect-virt` and starts only when VMware is detected and the helper exists.
- `kalipwm doctor` now distinguishes guarded VMware startup from an unguarded VM-specific command.
- Doctor display reporting now derives geometry from the connected-output line when available, preserving dynamic VMware dimensions even when the current mode is not exposed as a separate `*` entry.

### Validation

- `sh -n CONFIGS/config/bspwm/bspwmrc` and `bash -n SCRIPTS/kalipwm` passed during feature validation.
- On the representative VMware Kali VM, BSPWM restart preserved `Virtual-1` at `2318x1422` instead of forcing `1920x1080`, and the VMware desktop session remained active through `vmtoolsd -n vmusr`.
- On the primary bare-metal Kali host, BSPWM restart preserved the native `eDP-1` `2560x1600` display geometry and did not start any VMware desktop process; the connected HDMI output was also left untouched.
- The managed repository BSPWM policy and installed `~/.config/bspwm/bspwmrc` matched during bare-metal validation.
- Final Doctor output reached `19 OK | 0 WARN | 0 FAIL | 9 INFO` on VMware and `20 OK | 0 WARN | 0 FAIL | 8 INFO` on bare metal.
- Other virtualization types remain diagnostic only unless they have an explicitly supported startup policy; VMware-specific behavior is never enabled merely because another VM environment is detected.

## 2026-08-27 — Configuration backup and rollback

### Added

- `kalipwm backup` and `kalipwm backup --label NAME` for timestamped snapshots of KaliPWM-managed configuration.
- `kalipwm backups` for listing available snapshots newest first.
- `kalipwm rollback [BACKUP_ID|latest]` for restoring a specific or latest snapshot.
- `kalipwm rollback ... --dry-run` for validating and printing the restore plan without changing files or using `sudo`.
- Automatic `pre-rollback` safety snapshots before every real rollback.
- Automatic `pre-update` snapshots immediately before update replaces managed files.
- Automatic `pre-repair` snapshots before a real repair replaces managed files.

### Scope and safety

- Snapshots are stored per user under `~/.config/kalipwm/backups/` with a timestamp and label.
- Snapshot scope is intentionally limited to KaliPWM-managed BSPWM, Kitty, Picom, Polybar and sxhkd configuration, `.zshrc`, `.p10k.zsh`, `.tmux.conf.local` and canonical `/usr/bin/{target,screenshot,wallpaper}` helper links.
- Target state, persisted wallpaper choice, shell history, browser data and unrelated `~/.config` content are excluded.
- Snapshot creation uses a private `umask 077`; secrets manually placed inside a managed configuration file are naturally copied into that private snapshot.
- Rollback manifests accept only the explicitly supported managed home/system paths before restore actions are applied.
- A real rollback snapshots the current managed state first, so the operation itself is reversible.
- `kalipwm repair --dry-run` does not create a snapshot; it remains mutation-free and does not use `sudo`.
- `SCRIPTS/kalipwm-backup` is tracked executable (`100755`).

### Validation

- `bash -n` passed for `SCRIPTS/kalipwm`, `SCRIPTS/kalipwm-backup` and `SCRIPTS/kalipwm-repair` during feature validation.
- On the representative VMware Kali VM, a manual baseline snapshot was created, controlled drift in BSPWM and `.zshrc` was removed by rollback, a `pre-rollback` safety snapshot captured the drifted state, that safety snapshot was then restored successfully, and the clean baseline was restored again to prove the round trip in both directions.
- VMware public-command validation confirmed `kalipwm backup`, `kalipwm backups` and rollback dry-run through the installed `/usr/local/bin/kalipwm` command.
- VMware real repair created a `pre-repair` snapshot while repair dry-run created none; no APT/source-build/font-download activity occurred.
- VMware feature-update validation created a `pre-update` snapshot that captured deliberately drifted `.zshrc` and `bspwmrc` contents before update refreshed both managed files.
- On the primary bare-metal Kali host, a manual `baremetal-baseline` snapshot and real rollback removed controlled BSPWM/`.zshrc` drift with exit code `0` and created a `pre-rollback` safety snapshot.
- Bare-metal repair dry-run created no snapshot; real repair created a `pre-repair` snapshot with no forbidden installer/build activity.
- Bare-metal feature-update validation created a `pre-update` snapshot containing the controlled `.zshrc` and `bspwmrc` drift before deployment refreshed both files.
- Across all backup/rollback/update/repair tests, Target `172.16.18.10` and wallpaper choice `nomad-emblem` remained unchanged.
- Final diagnostics remained `18 OK | 1 WARN | 0 FAIL | 9 INFO` on VMware and `19 OK | 2 WARN | 0 FAIL | 7 INFO` on bare metal; remaining warnings were the intentionally deferred display/VM-awareness assumptions that were addressed in the subsequent hardware/VM-awareness work.

## 2026-08-27 — Flameshot on-demand session behavior

### Changed

- Removed the requirement to keep a persistent Flameshot process running under BSPWM; the managed `screenshot` helper launches Flameshot on demand.
- `kalipwm doctor` now treats an installed Flameshot executable as healthy even when no resident Flameshot process exists.
- Doctor reports `Flameshot is installed and available on demand` instead of warning about an absent background process.

### Validation

- On the representative VMware Kali VM, Flameshot was stopped completely, `kalipwm doctor` remained healthy at `18 OK | 1 WARN | 0 FAIL | 9 INFO`, Print launched a successful interactive capture, and Doctor remained unchanged afterward.
- On the primary bare-metal Kali host, Flameshot was stopped completely, Print launched a successful interactive capture, and Doctor remained at `19 OK | 2 WARN | 0 FAIL | 7 INFO` before and after capture.
- Flameshot may remain resident after a capture or exit; either process state is valid because capture availability is provided by the installed executable and managed helper rather than a required daemon.

## 2026-08-27 — `kalipwm repair`

### Added

- `kalipwm repair` for refreshing KaliPWM-managed configuration, executable permissions and canonical helper symlinks without rerunning the full installer.
- `kalipwm repair --dry-run` for showing the exact repair plan without using `sudo` or modifying files.
- `kalipwm repair --repo PATH` support for explicitly selecting an alternate KaliPWM checkout.
- Timestamped quarantine under `~/.cache/kalipwm/repair-backups/` for recognized legacy `~/.local/bin/{target,screenshot,wallpaper}` helper symlinks.

### Changed

- Repair now restores `/usr/bin/target`, `/usr/bin/screenshot`, `/usr/bin/wallpaper` and `/usr/local/bin/kalipwm` from the current checkout.
- Managed BSPWM/Polybar/Rofi/Kitty/Picom configuration, shell files, wallpapers and executable permissions are reapplied without reinstalling the toolchain.
- Recognized legacy PATH-shadow symlinks are moved into quarantine instead of being deleted.

### Safety

- Regular files and unrecognized symlink destinations under `~/.local/bin` are left untouched for manual review.
- Repair does not invoke APT, reinstall fonts, download third-party components or rebuild Polybar/Picom.
- Target state and persisted wallpaper choice under `~/.cache/kalipwm/` are not modified.
- A second repair run is idempotent and performs no additional quarantine when no recognized legacy shadows remain.

### Validation

- Syntax validation passed for both `SCRIPTS/kalipwm` and `SCRIPTS/kalipwm-repair`.
- VMware dry-run identified only the stale `target` PATH shadow; the real repair quarantined it, preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem`, showed no forbidden installer activity and improved diagnostics from `18 OK | 2 WARN | 0 FAIL | 9 INFO` to `18 OK | 1 WARN | 0 FAIL | 9 INFO`.
- The installed `kalipwm repair` command, help output, dry-run and real execution were validated directly on the representative VMware Kali VM.
- Bare-metal dry-run identified the stale Forest-era `target` and `screenshot` PATH shadows; the real repair quarantined both, preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem`, showed no forbidden installer activity and improved diagnostics from `19 OK | 4 WARN | 0 FAIL | 7 INFO` to `19 OK | 2 WARN | 0 FAIL | 7 INFO`.
- Second repair runs on both validation systems completed with exit code `0` and no additional quarantine actions.
- `SCRIPTS/kalipwm-repair` is tracked executable (`100755`).

## 2026-08-27 — `kalipwm update`

### Added

- `kalipwm update` for fast-forwarding the local KaliPWM checkout and refreshing managed desktop files without rerunning the complete installer.
- `kalipwm update --repo PATH` and `KALIPWM_REPO` support for explicitly selecting an alternate checkout location.
- Dirty-checkout protection that refuses to update when tracked or untracked local changes are present.

### Changed

- Updates now fetch `origin/main`, switch to local `main` when necessary and use `git pull --ff-only` so the management command never creates an implicit merge commit.
- After the Git update, KaliPWM reapplies managed BSPWM/Polybar/Rofi/Kitty/Picom configuration, shell configuration, bundled wallpapers, helper symlinks and `/usr/local/bin/kalipwm` only.
- Target state and persisted wallpaper choice remain outside the update deployment path and are preserved.

### Safety

- `kalipwm update` does not invoke APT, reinstall Nerd Fonts, rebuild Polybar/Picom or rerun `kalipwm.sh`.
- A dirty repository stops before fetch/deployment and prints the local changes that must be committed, stashed or removed.
- The post-fetch deployment is refused if the checkout unexpectedly becomes dirty.

### Validation

- `bash -n SCRIPTS/kalipwm` passed before live update testing.
- Dirty-checkout refusal returned exit code `1` and left the representative VMware checkout unchanged.
- VMware update validation preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem`, showed no APT/build activity and finished with `18 OK | 2 WARN | 0 FAIL | 9 INFO` from `kalipwm doctor`.
- Bare-metal update validation exited `0`, preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem`, showed no APT/build activity and finished with `19 OK | 4 WARN | 0 FAIL | 7 INFO` from `kalipwm doctor`.

## 2026-08-27 — Idempotent installer reruns

### Changed

- Re-running `bash kalipwm.sh` now reuses existing managed components instead of deleting or blindly recloning them.
- Existing Oh My Zsh, Powerlevel10k, Zsh plugin, fzf and tmux installations are reused.
- Installed Hack Nerd Font and JetBrainsMono Nerd Font families skip repeat downloads.
- Existing Kitty, Polybar, Polybar themes and Picom installations skip unnecessary reinstall/build work when already available.
- APT continues to ensure required packages and build dependencies while leaving already-current packages untouched.
- KaliPWM-managed configuration, helper symlinks, executable permissions and bundled wallpapers are reapplied on rerun.
- A plain installer rerun preserves the saved wallpaper choice; fresh installs with no persisted choice continue to default to `auto`.

### Safety

- Existing source paths that are not valid Git checkouts are no longer deleted automatically; the installer stops with an explicit message so the user can inspect the path first.
- Managed source checkouts are reused without destructive recloning.

### Validation

- Static `bash -n` validation passed before full rerun testing.
- A plain rerun on the representative VMware Kali VM exited `0`, preserved the saved `nomad-emblem` wallpaper, reused all expected existing components and produced no unexpected Git clones.
- Post-rerun VMware diagnostics reported `18 OK | 2 WARN | 0 FAIL | 9 INFO`.
- A plain rerun on the primary bare-metal Kali host exited `0`, preserved the saved `nomad-emblem` wallpaper, reused the existing toolchain and produced no unexpected Git clones.
- Post-rerun bare-metal diagnostics reported `19 OK | 4 WARN | 0 FAIL | 7 INFO`; remaining warnings were stale PATH-shadow helpers and legacy VM/display assumptions rather than installer failures.

## 2026-08-27 — `kalipwm doctor` diagnostics

### Added

- `/usr/local/bin/kalipwm` management command installed by KaliPWM.
- `kalipwm doctor` read-only diagnostic report.
- System checks for Kali/X11, virtualization and current display/resolution.
- Desktop checks for BSPWM, sxhkd, Polybar, Picom, Rofi and Flameshot.
- Managed helper checks for `target`, `screenshot` and `wallpaper`, including PATH-shadowing detection.
- Configuration/font/state checks for Obsidian BSPWM/Polybar, Nerd Fonts, Target and current wallpaper.
- Network checks for the default interface, Wi-Fi and common VPN tunnel interfaces.
- Optional battery, GPU and fan telemetry reporting.
- Configuration warnings for legacy hard-coded `Virtual1` output and VMware-specific session startup.

### Changed

- Diagnostic status is classified as `[OK]`, `[INFO]`, `[WARN]` or `[FAIL]` so optional hardware absence is not treated as broken configuration.
- `kalipwm doctor` returns exit code `1` only when required-state failures are present; warnings alone remain non-fatal.

### Validation

- Diagnostic behavior was validated on a representative VMware Kali VM and the primary bare-metal Kali host.
- VMware validation confirmed real display discovery, optional-hardware handling and PATH-shadowing detection.
- Bare-metal validation confirmed `eDP-1` display detection, `wlan0` Wi-Fi detection, battery/NVIDIA telemetry and warnings for stale VM/display assumptions.
- The installed `/usr/local/bin/kalipwm` command, help output and doctor execution were validated directly on bare metal.
- The doctor remained read-only and did not use `sudo` or modify configuration during validation.

## 2026-08-27 — English-only source and CLI cleanup

### Changed

- Maintained installer comments, progress messages, warnings, errors and completion output are now English-only.
- Installer attribution now credits both the original `afsh4ck/kalipwm` project and the KaliPWM Obsidian fork.
- `kalipwm.sh` is tracked as executable (`100755`) to prevent repeated local file-mode drift during testing and branch switches.

### Validation

- `bash -n kalipwm.sh` completed without syntax errors.
- Installer credit lines were verified on the representative VMware Kali VM.
- A repository-wide language audit returned no matches for the legacy non-English strings checked by the project.

## 2026-08-27 — Wallpaper runtime/install separation

### Added

- Standalone `wallpaper` command installed by KaliPWM.
- Explicit `--install-wallpaper NAME` option for choosing a wallpaper during a full installation.
- Runtime `--wallpaper NAME` and `--set-wallpaper NAME` actions that exit after changing the wallpaper.

### Changed

- Wallpaper switching is now separated from the full installer lifecycle.
- Runtime wallpaper changes use the existing Obsidian selector and persistent cache state.
- Invalid wallpaper names are rejected before installation work begins.

### Fixed

- `bash kalipwm.sh --wallpaper NAME` no longer continues into `apt update`, package installation or environment deployment.
- Changing a wallpaper no longer risks reinstalling KaliPWM.

### Validation

- `wallpaper list`, multiple runtime wallpaper selections and `bash kalipwm.sh --wallpaper NAME` were validated on the representative VMware Kali VM.
- Runtime switching returned directly to the shell without entering installer stages.

## 2026-08-27 — Flameshot screenshot workflow

### Added

- Flameshot as the default KaliPWM screenshot dependency.
- Interactive Flameshot selection from the Print Screen workflow.
- Persistent Flameshot session startup under BSPWM for reliable GUI and clipboard behavior.
- `screenshot` helper modes for interactive selection, full-screen capture and screen capture.

### Changed

- `scrot` was removed from KaliPWM installer dependencies.
- `Print` and `Ctrl + Print` now open the native Flameshot interactive interface.
- `Alt + Print` uses interactive region selection because Flameshot does not provide a native active-window CLI capture mode.
- Interactive capture no longer passes a final `--path` action, preserving native Flameshot shortcuts and annotation behavior.

### Fixed

- `Ctrl + C` clipboard copy after selecting a Flameshot region.
- `Ctrl + S`, undo/redo and annotation-tool behavior inside the Flameshot GUI.
- Fresh-VM screenshot behavior that previously depended on `scrot` or on Flameshot already being installed outside KaliPWM.

### Validation

- Interactive selection and screenshot shortcuts validated on the representative VMware Kali VM.
- Native Flameshot clipboard and selection workflow confirmed before promotion to `main`.

## 2026-08-26 — Obsidian v2 foundation

Current stable `main` baseline.

### Added

- Obsidian v2 Polybar layout.
- Roman-numeral BSPWM workspaces.
- Wi-Fi interface/IP telemetry.
- VPN interface/IP telemetry.
- Per-user Target state and Polybar display.
- Compact CPU/GPU/RAM/fan/audio/power telemetry.
- Dedicated compact Rofi power confirmation theme.
- Obsidian City wallpaper variants.
- Nomad Monolith wallpaper variants.
- Nomad Emblem wallpaper variants.
- Persistent wallpaper choice.
- Installer wallpaper selection flags.

### Changed

- Target display no longer depends on VPN state.
- Polybar spacing and icon sizing were refined for the Obsidian layout.
- RAM/fan/power presentation was compacted for better right-side density.
- Native `cat` and Vim behavior were restored explicitly.
- Public README was moved away from the original upstream presentation and toward KaliPWM Obsidian-specific documentation.

### Fixed

- Target command/Polybar helper divergence between machines.
- Oversized Rofi confirmation window caused by reusing the five-row power menu theme.
- Duplicate target helper behavior that could produce inconsistent state.

## Maintenance convention

When a future feature reaches `main`, update whichever of these are relevant:

- `README.md` — current stable behavior and public usage;
- `ROADMAP.md` — move the task from planned/in-progress to done;
- `CHANGELOG.md` — record the user-visible change;
- install/help output — when CLI usage changes.

Documentation should describe a fresh clone of `main`, not the maintainer's local machine state.