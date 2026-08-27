# Changelog

This changelog tracks user-visible changes that reach `main`.

The rule for this repository is simple: when a task is validated and merged into `main`, its documentation status must be updated in the same completion cycle. Experimental branch work is not recorded as stable functionality.

## Unreleased

No unreleased feature is considered stable until it reaches `main`.

Current development work is tracked in [`ROADMAP.md`](ROADMAP.md).

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
