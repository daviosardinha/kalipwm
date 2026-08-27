# KaliPWM Obsidian Roadmap

This roadmap tracks the direction of the `daviosardinha/kalipwm` fork.

The project is evolving from a customized Kali desktop installer into a **repeatable offensive-security workstation layer** that behaves consistently across clean Kali installations, VMs and bare-metal systems.

**Project language:** English only. Documentation, maintained source comments and user-facing CLI output must be written in English.

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
- Flameshot is launched on demand by the managed screenshot helper; no persistent background process is required;
- full/screen captures can still be saved under `~/screenshots/` through the helper;
- the interactive workflow and on-demand process lifecycle were validated on both the representative VMware Kali VM and the primary bare-metal Kali host.

### ✅ Separate wallpaper switching from installation

Runtime wallpaper changes are now isolated from the full installer.

Completed outcome:

```bash
wallpaper list
wallpaper nomad-emblem-16x9
wallpaper nomad-monolith-16x9
wallpaper city-16x9
wallpaper auto
```

- the installer creates the standalone `wallpaper` command;
- `bash kalipwm.sh --wallpaper NAME` changes only the wallpaper and exits;
- changing a wallpaper no longer triggers package installation or a KaliPWM reinstall;
- `bash kalipwm.sh --install-wallpaper NAME` explicitly selects a wallpaper for a full installation;
- invalid wallpaper names fail before any installation work begins;
- the selected wallpaper remains persistent through the existing KaliPWM cache state;
- runtime switching and installer separation were validated on the representative VMware Kali VM before promotion to `main`.

### ✅ English-only source and CLI cleanup

Legacy non-English text inherited from upstream has been removed from the maintained installer and audited repository content.

Completed outcome:

- installer comments and progress messages use English;
- root/sudo errors, warnings and completion messages use English;
- installer attribution credits both the original `afsh4ck/kalipwm` project and KaliPWM Obsidian;
- `kalipwm.sh` is tracked as executable (`100755`) to avoid recurring file-mode drift during testing;
- a repository-wide language audit returned no matches for the legacy non-English strings used by the project;
- future maintained documentation, comments and user-facing CLI output remain English-only.

---

## Phase 3 — Reliability and reproducibility

### ✅ `kalipwm doctor`

A read-only management command now explains why two KaliPWM installations behave differently without changing either machine.

Completed outcome:

```bash
kalipwm doctor
```

- the installer deploys the management command to `/usr/local/bin/kalipwm`;
- Kali/X11, virtualization and current display/resolution are reported;
- BSPWM, sxhkd, Polybar, Picom and Rofi runtime state plus Flameshot availability are checked;
- managed `target`, `screenshot` and `wallpaper` helpers are checked independently from PATH shadowing;
- Obsidian BSPWM/Polybar configuration and required Nerd Fonts are checked;
- Target and current wallpaper state are reported without modification;
- default networking, Wi-Fi and common VPN tunnel interfaces are reported;
- battery, GPU and fan telemetry are treated as optional hardware capabilities rather than automatic failures;
- legacy hard-coded `Virtual1` display configuration and VMware-only session startup are surfaced as warnings when appropriate;
- `[OK]`, `[INFO]`, `[WARN]` and `[FAIL]` classifications distinguish healthy state, optional information, non-fatal drift and broken required state;
- the command never uses `sudo` and never repairs or changes configuration;
- one or more `FAIL` findings produce exit code `1`, while warnings alone do not fail the command;
- diagnostic behavior was validated on both the representative VMware Kali VM and the primary bare-metal Kali host.

### ✅ Idempotent installer

Re-running KaliPWM now reuses an existing installation instead of destructively rebuilding the whole environment.

Completed outcome:

- existing Oh My Zsh installations are reused rather than deleted;
- existing Powerlevel10k, Zsh plugin, fzf and tmux Git checkouts are reused;
- installed Hack Nerd Font and JetBrainsMono Nerd Font families skip download/reinstallation;
- an existing Kitty application bundle is reused;
- existing Polybar and Picom installations skip source rebuilds;
- existing Polybar themes skip bootstrap when the checkout is already present;
- required packages and build dependencies remain ensured through APT without reinstalling already-current packages;
- KaliPWM-managed configuration, helper symlinks, permissions and bundled wallpapers are reapplied on rerun;
- a plain `bash kalipwm.sh` rerun preserves the persisted wallpaper choice, while a fresh install with no saved state still defaults to `auto`;
- unexpected non-Git directories at managed source-checkout paths cause an explicit failure instead of being deleted automatically;
- plain reruns completed with exit code `0` and no unexpected Git clones on both the representative VMware Kali VM and the primary bare-metal Kali host;
- post-rerun `kalipwm doctor` showed `0 FAIL` on both validation systems.

### ✅ `kalipwm update`

Update an installed KaliPWM environment from its checked-out repository without reinstalling the complete toolchain.

Completed outcome:

```bash
kalipwm update
```

- a clean checkout is required before any update is attempted;
- the command fetches `origin/main`, switches to local `main` when needed and uses `--ff-only` to avoid implicit merge commits;
- after the Git update, only KaliPWM-managed configuration, shell files, wallpapers, helper symlinks and `/usr/local/bin/kalipwm` are refreshed;
- an automatic `pre-update` snapshot is created immediately before managed files are replaced;
- APT, Nerd Font installation and Polybar/Picom source builds are not invoked;
- Target state and saved wallpaper choice remain untouched under the KaliPWM cache directory;
- the default checkout is `~/kalipwm`, with `--repo PATH` and `KALIPWM_REPO` available for explicit alternate locations;
- dirty-checkout refusal was validated before deployment testing;
- update deployment and automatic pre-update snapshots were validated on both the representative VMware Kali VM and the primary bare-metal Kali host;
- both validation systems preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem`, showed no forbidden installer activity and finished with `0 FAIL` from `kalipwm doctor`.

### ✅ `kalipwm repair`

Repair only KaliPWM-managed configuration, helper permissions and canonical command symlinks without reinstalling the complete toolchain.

Completed outcome:

```bash
kalipwm repair
kalipwm repair --dry-run
```

- managed BSPWM/Polybar/Rofi/Kitty/Picom configuration, shell files, bundled wallpapers and executable permissions are reapplied;
- canonical `/usr/bin/target`, `/usr/bin/screenshot`, `/usr/bin/wallpaper` and `/usr/local/bin/kalipwm` are restored;
- recognized legacy `~/.local/bin/{target,screenshot,wallpaper}` symlinks are quarantined under a timestamped `~/.cache/kalipwm/repair-backups/` directory instead of being deleted;
- regular files and unrecognized symlink destinations are intentionally left untouched for manual review;
- `--dry-run` reports the exact planned actions without using `sudo`, changing files or creating a backup;
- a real repair creates an automatic `pre-repair` snapshot before replacing managed files;
- APT, font installation, third-party downloads and Polybar/Picom source builds are not invoked;
- Target state and persisted wallpaper choice are not modified;
- the command is idempotent: a second repair run performs no additional quarantine when no recognized legacy shadows remain;
- VMware validation removed the stale `target` PATH shadow and improved `kalipwm doctor` from `18 OK | 2 WARN | 0 FAIL | 9 INFO` to `18 OK | 1 WARN | 0 FAIL | 9 INFO`;
- bare-metal validation quarantined stale `target` and `screenshot` Forest-era shadows and improved `kalipwm doctor` from `19 OK | 4 WARN | 0 FAIL | 7 INFO` to `19 OK | 2 WARN | 0 FAIL | 7 INFO`;
- automatic pre-repair snapshot behavior was validated on both systems with Target `172.16.18.10` and wallpaper choice `nomad-emblem` preserved.

### ✅ Configuration backup and rollback

Timestamped snapshots now make managed configuration changes reversible.

Completed outcome:

```bash
kalipwm backup
kalipwm backup --label before-change
kalipwm backups
kalipwm rollback latest --dry-run
kalipwm rollback latest
kalipwm rollback BACKUP_ID
```

- snapshots are stored per user under `~/.config/kalipwm/backups/` with a timestamp and label;
- the snapshot scope is intentionally limited to KaliPWM-managed BSPWM, Kitty, Picom, Polybar and sxhkd configuration, `.zshrc`, `.p10k.zsh`, `.tmux.conf.local` and canonical `/usr/bin/{target,screenshot,wallpaper}` helper links;
- Target state, wallpaper-choice state, shell history, browser data and unrelated `~/.config` content are excluded;
- snapshot creation uses a private `umask 077`;
- `kalipwm rollback --dry-run` validates and prints the restore plan without changing files or using `sudo`;
- a real rollback first creates a `pre-rollback` safety snapshot, making the rollback operation itself reversible;
- update automatically creates `pre-update` snapshots and repair automatically creates `pre-repair` snapshots before replacing managed files;
- controlled-drift rollback was validated on the representative VMware VM and the primary bare-metal host;
- on VMware, a `pre-rollback` safety snapshot was restored to recover the deliberately drifted state and the baseline was then restored again, proving the round trip in both directions;
- automatic `pre-update` snapshots on both systems captured deliberately drifted `.zshrc` and `bspwmrc` contents before update refreshed them;
- manual backup/rollback, rollback dry-run, automatic pre-repair and automatic pre-update validation all preserved Target `172.16.18.10` and wallpaper choice `nomad-emblem` and finished with `0 FAIL` from `kalipwm doctor`.

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
- install/update/repair/backup/rollback documentation;
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
