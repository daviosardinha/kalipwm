# Changelog

This changelog tracks user-visible changes that reach `main`.

The rule for this repository is simple: when a task is validated and merged into `main`, its documentation status must be updated in the same completion cycle. Experimental branch work is not recorded as stable functionality.

## Unreleased

No unreleased feature is considered stable until it reaches `main`.

Current development work is tracked in [`ROADMAP.md`](ROADMAP.md).

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
