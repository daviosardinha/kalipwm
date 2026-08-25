# KaliPWM V1 validation status

Status: V1 implementation baseline is stable on the primary bare-metal machine and has completed a full KVM/QEMU install/use/uninstall round-trip. Static CI is green. VMware guest validation remains the main environment-specific release gate that has not yet been exercised.

## Validated on bare metal — Lenovo 83F5

- Kali GNU/Linux Rolling detected correctly.
- Environment detected as `baremetal`.
- Internal battery detection selects `BAT0` and ignores peripheral `scope=Device` battery-class devices.
- Mains adapter detection selects `ADP0`.
- Backlight detected dynamically.
- Wi-Fi and Ethernet detected dynamically.
- Internal display detected as `eDP-1`.
- External USB-C display is discovered dynamically and placed according to the configured bare-metal preference.
- Live USB-C disconnect/reconnect reconciles XRandR, BSPWM, workspaces and Polybar even when the provider-backed output name changes (observed `DP-1` -> `DP-1-1`).
- Hybrid XRandR providers remain untouched; KaliPWM does not force NVIDIA provider routing or desktop ownership.
- Suspend/resume with the external monitor attached preserves the active topology, BSPWM workspaces I-V, Polybar and the display watcher.
- VMware Workstation host configuration and the existing NVIDIA PRIME/open-module setup remain untouched.

## BSPWM application/session validation

Validated live on bare metal:

- BSPWM login and normal tiled application use.
- Kitty launch through `Super+Enter`.
- Rofi launch through `Super+D`.
- Picom running with the Obsidian Tactical compositor configuration.
- Polybar renders correctly on internal and external monitors and rebuilds one bar per active monitor after hotplug.
- Battery module agrees with the runtime battery helper.
- Telemetry reports CPU/GPU/fan data without polling a suspended NVIDIA dGPU through `nvidia-smi`.
- Volume up/down/mute work through PipeWire `wpctl` bindings.
- Brightness controls work through `brightnessctl`.
- Volume and brightness OSD notifications render through the Obsidian-themed Dunst configuration.
- Obsidian power menu opens correctly, renders all Nerd Font icons, reports uptime and presents the confirmation flow.
- Flameshot interactive capture works on the native X11 path and preserves clipboard-only behavior for `Ctrl+C`.

## Regressions found and fixed during live QA

### Kali rolling package names

- Initial APT resolution failed because obsolete/no-candidate desktop integration package names were still referenced.
- Installer now uses `network-manager-applet`, `nm-connection-editor` and `mate-polkit`, and checks the real APT Candidate value before installation.

### Hybrid GPU telemetry

- Original telemetry could call `nvidia-smi` on every Polybar poll and repeatedly wake a sleeping hybrid-laptop dGPU.
- Runtime telemetry now checks NVIDIA PCI runtime PM state before using `nvidia-smi`.
- `KALIPWM_FORCE_GPU_TELEMETRY=1` remains an explicit override.
- Polybar telemetry polling is intentionally conservative.

### Flameshot under BSPWM

- Flameshot 14 initially timed out on the XDG Desktop Portal Screenshot interface.
- KaliPWM now ships `useX11LegacyScreenshot=true` and launches GUI capture without a forced save path.
- `Ctrl+C` remains clipboard-only, while explicit full-desktop save remains available separately.

### Dynamic display reconciliation

- A reconnected USB-C monitor can return under a different provider-backed XRandR output name.
- The watcher now mirrors the topology already reported by XRandR, adds newly connected BSPWM monitors, migrates desktops off stale monitor objects before removing them, preserves I-V, removes empty placeholder desktops, and relaunches Polybar for the active monitor set.
- Watcher startup records an initial topology signature to avoid racing the BSPWM-owned first Polybar launch.

### Multimedia keys and OSD

- The laptop generates the expected XF86 audio keycodes and the audio stack itself was healthy.
- The validated path is `sxhkd` -> explicit `wpctl` command against the default PipeWire sink.
- Dunst provides replaceable volume/brightness progress notifications styled to the Obsidian Tactical palette.

### Power menu

- Helper files copied with non-executable repository modes could make the Polybar power button silently fail.
- Menu helpers are now invoked through Bash rather than relying on the source executable bit.
- Legacy Feather glyphs were replaced with the V1 Nerd Font vocabulary.

## Recovery validation

### Rollback

- A transaction checkpoint was created on bare metal.
- A probe file was added inside a managed Dunst path.
- `--rollback` restored the checkpoint and removed the probe: PASS.
- Rollback now rehydrates `sxhkd` when BSPWM remains active so restored shortcuts do not depend on the terminal that invoked rollback.

### Trusted uninstall baseline

- Fresh KVM installation created `baseline=trusted` before KaliPWM changed the user configuration.
- Uninstall restored the trusted pre-KaliPWM baseline and removed KaliPWM-managed config, helper and wallpaper targets.
- Uninstall now terminates KaliPWM's persistent display watcher and its own Polybar instance, then gracefully ends a still-running BSPWM session so LightDM can return to the restored desktop.
- Legacy installations that predate complete state tracking still refuse destructive uninstall rather than inventing a baseline.
- The duplicate legacy backup creator in `install.sh` has been retired; `SCRIPTS/kalipwm-state` is now the single recovery-state owner for new installs.

## KVM/QEMU validation — Proxmox Kali guest

Fresh guest validation completed on a QEMU/KVM VM:

- Environment detected as `kvm`.
- Platform detected as QEMU.
- `eth0` detected dynamically.
- No fake battery, AC adapter, backlight, Wi-Fi or internal laptop display assumptions were introduced.
- `Virtual-1` detected as the connected virtual display.
- KVM guest packages `spice-vdagent` and `qemu-guest-agent` installed when candidates were available.
- Trusted pre-install baseline and transaction checkpoint were created.
- First BSPWM login succeeded.
- BSPWM tracked `Virtual-1` with canonical workspaces I-V.
- Polybar, sxhkd, Dunst, Picom and the display watcher started.
- Manual RandR change from 1280x800 to 1920x1080 and back preserved BSPWM, I-V, Polybar and the watcher.
- Full uninstall returned the VM to its original Kali XFCE desktop with KaliPWM-managed paths removed.
- noVNC/SPICE/QEMU-agent host-side enablement is treated as hypervisor console configuration, not a KaliPWM desktop failure.

For VM profiles, physical external-monitor positioning is now reported as `n/a`; the right/left/above/below/mirror preference is a bare-metal concept only.

## Static CI

Static checks cover, among other things:

- forbidden legacy display/network/timezone/editor assumptions;
- current Kali package candidate handling;
- power-supply detection;
- hybrid GPU telemetry gating;
- Flameshot X11 behavior;
- BSPWM startup process handling;
- rollback shortcut rehydration;
- uninstall stale-session cleanup;
- dynamic monitor/workspace/Polybar reconciliation;
- Obsidian Tactical Nerd Font/icon consistency;
- single-owner recovery state and VM display-summary semantics.

## Pending before merge

- VMware Kali guest install/session/uninstall validation.
- Optional VirtualBox guest smoke validation if an environment is available.
- Reproducibility hardening for remote shell/theme dependencies and downloaded font archives.
- Final documentation/release-gate review and PR cleanup.
