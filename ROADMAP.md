# KaliPWM Obsidian Roadmap

This roadmap tracks the direction of the `daviosardinha/kalipwm` fork.

The project is evolving from a customized Kali desktop installer into a **repeatable offensive-security workstation layer** that behaves consistently across clean Kali installations, VMs and bare-metal systems.

**Project language:** English only. Documentation, user-facing CLI output, comments and newly maintained project content must be written in English. Remaining legacy non-English strings inherited from upstream are scheduled for cleanup before `v1.0.0`.

Statuses:

- ✅ **Done** — validated and available on `main`
- 🚧 **In progress** — under active development or validation; not yet stable on `main`
- ⏳ **Planned** — accepted direction, not started or not yet ready for implementation
- 💡 **Candidate** — useful idea that still needs design/priority review

---

## Phase 1 — Obsidian foundation

### ✅ Obsidian desktop identity

- Obsidian visual language across BSPWM, Polybar and Rofi.
- Roman-numeral workspaces.
- Compact Polybar layout.
- Larger dedicated status-icon font.
- Obsidian wallpaper family.

### ✅ Operational Polybar telemetry

- Wi-Fi interface and local IP.
- VPN interface and VPN IP.
- Target state.
- CPU usage and temperature.
- GPU telemetry where available.
- RAM usage.
- Compact fan RPM.
- Audio state.
- AC/battery state.
- Clock and power menu.

### ✅ Target workflow

- `target <IP>` sets the current target.
- `target` reads it.
- `target reset` clears it.
- Target state is per-user and independent of VPN connectivity.

### ✅ Wallpaper library and persistence

- City 16:9 and ultrawide variants.
- Nomad Monolith standard and 16:9 variants.
- Nomad Emblem standard and 16:9 variants.
- Persistent wallpaper choice under the KaliPWM cache directory.

### ✅ Rofi power confirmation cleanup

- Dedicated compact confirmation theme.
- No oversized empty five-row confirmation window.

---

## Phase 2 — Close current reliability gaps

### ✅ Flameshot as the default screenshot workflow

The screenshot workflow is now validated and promoted to stable behavior.

Completed outcome:

- `flameshot` is installed by default;
- `scrot` is removed from KaliPWM dependencies;
- Print Screen shortcuts launch Flameshot interactive selection;
- the helper preserves native Flameshot actions such as `Ctrl + C`, `Ctrl + S`, undo/redo and annotation tools;
- Flameshot is kept available in the BSPWM session so clipboard behavior remains consistent;
- full/screen captures can still be saved under `~/screenshots/` through the helper;
- the interactive workflow was validated on the representative VMware Kali VM before promotion to `main`.

### 🚧 Separate wallpaper switching from installation

Changing a wallpaper must never trigger a KaliPWM reinstall.

Target UX:

```bash
wallpaper list
wallpaper nomad-emblem-16x9
wallpaper nomad-monolith
wallpaper city-16x9
wallpaper auto
```

The full installer should remain a separate explicit action.

### ⏳ English-only source and CLI cleanup

Remove remaining legacy non-English text inherited from upstream so the repository follows one language consistently.

Scope:

- installer comments and progress messages;
- errors and warnings;
- helper-script comments where maintained by this fork;
- documentation and examples;
- future user-facing command help.

New changes must use English immediately; this task covers legacy content that still needs migration.

---

## Phase 3 — Reliability and reproducibility

### ⏳ `kalipwm doctor`

One diagnostic command should explain why two machines behave differently.

Candidate checks:

```text
[OK] BSPWM
[OK] Polybar Obsidian v2
[OK] sxhkd
[OK] Rofi
[OK] Flameshot
[OK] Picom
[OK] Nerd Fonts
[OK] target helper
[OK] wallpaper helper
[OK] Wi-Fi interface
[OK] VPN detection
[WARN] Battery unavailable
[WARN] GPU telemetry unavailable
```

The command should distinguish between expected hardware absence and actual broken configuration.

### ⏳ Idempotent installer

Re-running KaliPWM should repair/update the environment rather than blindly rebuilding everything.

Areas to address:

- existing Oh My Zsh installation;
- existing Powerlevel10k/plugins;
- existing Polybar source/build directory;
- existing Picom checkout/build;
- existing fonts;
- existing configuration directories;
- already-installed packages;
- safe symlink replacement.

### ⏳ `kalipwm update`

Update the local KaliPWM configuration from a checked-out repository without reinstalling the complete toolchain.

### ⏳ `kalipwm repair`

Repair only managed configuration, helpers, permissions and symlinks.

### ⏳ Configuration backup and rollback

Before replacing user-managed files, create a timestamped backup such as:

```text
~/.config/kalipwm/backups/2026-08-27-...
```

Target command:

```bash
kalipwm rollback
```

---

## Phase 4 — Hardware and VM awareness

### ⏳ Remove hard-coded display assumptions

Replace legacy assumptions such as a fixed `Virtual1` output with dynamic monitor discovery.

Target order during BSPWM startup:

1. discover/configure displays;
2. apply the selected wallpaper;
3. launch Polybar;
4. start Picom and remaining session services.

### ⏳ Detect runtime environment

Adapt startup/configuration for:

- bare metal;
- VMware;
- VirtualBox;
- other common virtualized Kali environments where practical.

VM-specific helpers should only run when the matching environment exists.

### ⏳ Hardware-adaptive Polybar

Modules should disappear or degrade cleanly when hardware is unavailable.

Examples:

- no battery → hide battery block;
- no readable GPU telemetry → hide/neutralize GPU block;
- no fan sensors → hide fan block;
- no VPN → show a clean disconnected state;
- Ethernet/Wi-Fi presentation should reflect interfaces actually present.

---

## Phase 5 — KaliPWM management UX

### ⏳ KaliPWM Control Center

A fast Rofi-based control surface rather than a heavy settings application.

Candidate menu:

```text
Network
VPN
Target
Wallpaper
Screenshot
Display
Audio
System
Diagnostics
Power
```

### ⏳ Polybar click actions

Candidate interactions:

- Wi-Fi → NetworkManager connection UI;
- VPN → connection/status action;
- Target → set/reset menu;
- volume → `pavucontrol`;
- power/battery → detail view;
- wallpaper → selector.

The visible bar should remain compact even as interactive behavior expands.

---

## Phase 6 — Security and maintainability

### ⏳ Shell quality pass

- run ShellCheck against managed scripts;
- standardize strict/safe shell behavior where appropriate;
- quote paths and variables consistently;
- remove stale duplicate helpers;
- reduce hidden dependencies between old and Obsidian profiles.

### ⏳ Reproducible external dependencies

Where practical:

- pin important third-party versions/commits;
- avoid silently pulling arbitrary latest revisions during every install;
- reduce `curl | sh`-style installation paths;
- validate downloads before execution when feasible.

### ⏳ Installer failure handling

A partial failure should explain what failed and how to resume/repair rather than leaving an ambiguous half-installed environment.

---

## Phase 7 — Public release quality

### ⏳ Fresh-install validation matrix

Before `v1.0.0`, validate at minimum:

- clean Kali VM;
- primary bare-metal Kali host;
- standard 16:9 display;
- ultrawide/multi-monitor case where available;
- VPN connected/disconnected states;
- battery/no-battery hardware cases where available.

### ⏳ Public documentation pass

- current screenshots from this fork;
- install/update/repair documentation;
- known limitations;
- supported/tested environments;
- troubleshooting using `kalipwm doctor`;
- migration notes for users of earlier builds.

### ⏳ `v1.0.0`

Tag the first release only after the fresh-install workflow is reproducible and the public documentation matches `main`.

---

## Candidate ideas

These are intentionally not commitments yet.

### 💡 Profiles

Potential presets for different use cases:

- laptop;
- VM/CTF;
- ultrawide workstation;
- minimal/low-resource mode.

### 💡 Workspace context

Allow Polybar or Rofi to show lightweight engagement context such as lab/CTF name alongside Target state without exposing sensitive data by default.

### 💡 Exportable diagnostics

`kalipwm doctor --report` could generate a sanitized diagnostic bundle suitable for troubleshooting without collecting secrets, shell history or credentials.

### 💡 Release self-check

A lightweight script or CI job that validates expected files, executable bits, shell syntax and documentation references before a release.

---

## Definition of done

A task is not considered finished merely because the code works on one machine.

For changes that affect the installed desktop, the preferred completion flow is:

1. implement on a feature/fix branch;
2. test the relevant behavior on the primary host;
3. test on a clean or representative VM when the change can be environment-sensitive;
4. confirm existing functionality was not regressed;
5. update the relevant documentation;
6. merge/squash into `main`;
7. immediately update README/ROADMAP/changelog status so public documentation describes what `main` actually provides.

Experimental branch behavior must stay marked as **in progress** until it reaches `main`.
