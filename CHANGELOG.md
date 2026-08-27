# Changelog

This changelog tracks user-visible changes that reach `main`.

The rule for this repository is simple: when a task is validated and merged into `main`, its documentation status must be updated in the same completion cycle. Experimental branch work is not recorded as stable functionality.

## Unreleased

No unreleased feature is considered stable until it reaches `main`.

Current development work is tracked in [`ROADMAP.md`](ROADMAP.md).

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
