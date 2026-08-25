#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '== Bash syntax ==\n'
while IFS= read -r file; do
  bash -n "$file"
  printf 'PASS %s\n' "$file"
done < <(
  {
    printf '%s\n' kalipwm.sh install.sh
    find SCRIPTS -maxdepth 1 -type f -print
    find CONFIGS/config/bspwm -type f \( -name '*.sh' -o -name 'bspwmrc' \) -print
    find CONFIGS/config/polybar -type f -name '*.sh' -print
  } | sort -u
)

printf '\n== Legacy assumption guard ==\n'
legacy_regex='Virtual1|--mode[[:space:]]+1920x1080|adapter[[:space:]]*=[[:space:]]*ADP1|interface[[:space:]]*=[[:space:]]*(wlan0|eth0|tun0)|alias[[:space:]]+(cat|vim)=|nvim-linux|timedatectl[[:space:]]+set-timezone'
if grep -RInE "$legacy_regex" CONFIGS SCRIPTS install.sh kalipwm.sh; then
  echo 'FAIL: legacy hard-coded assumption detected.' >&2
  exit 1
fi
echo 'PASS no forbidden legacy assumptions'

printf '\n== Recovery state ownership guard ==\n'
! grep -q '^BACKUP_ROOT=' install.sh
! grep -q '^MANAGED_PATHS=' install.sh
! grep -q '^create_backup()' install.sh
! grep -q '^restore_backup()' install.sh
grep -q 'Recovery state is managed by SCRIPTS/kalipwm-state' install.sh
grep -q 'Recovery          : trusted baseline + transaction checkpoint state' install.sh
echo 'PASS installer no longer creates a duplicate legacy backup path'

printf '\n== VM display preference guard ==\n'
grep -A8 '^choose_display_preferences()' install.sh | grep -q "EXTERNAL_POSITION=''"
grep -q 'External position  : ${EXTERNAL_POSITION:-n/a}' install.sh
grep -q 'External position : ${EXTERNAL_POSITION:-n/a}' install.sh
echo 'PASS VM profiles report external display positioning as n/a'

printf '\n== Kali rolling package guard ==\n'
if grep -nE '^[[:space:]]*network-manager-gnome([[:space:]]|$)|^[[:space:]]*policykit-1-gnome([[:space:]]|$)' install.sh; then
  echo 'FAIL: obsolete/no-candidate Kali package name is present in installer list.' >&2
  exit 1
fi
grep -q 'network-manager-applet' install.sh
grep -q 'nm-connection-editor' install.sh
grep -q 'mate-polkit' install.sh
grep -q 'package_has_candidate' install.sh
echo 'PASS installer uses current desktop integration packages and candidate checks'

printf '\n== Power-supply detection regression ==\n'
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

mkdir -p \
  "$fixture/apple_mfi_fastcharge_3-9" \
  "$fixture/BAT0" \
  "$fixture/ADP0" \
  "$fixture/ucsi-source-psy-USBC000:001"

printf 'Battery\n' > "$fixture/apple_mfi_fastcharge_3-9/type"
printf 'Device\n' > "$fixture/apple_mfi_fastcharge_3-9/scope"

printf 'Battery\n' > "$fixture/BAT0/type"
printf '1\n' > "$fixture/BAT0/present"
printf '41\n' > "$fixture/BAT0/capacity"
printf 'Discharging\n' > "$fixture/BAT0/status"

printf 'Mains\n' > "$fixture/ADP0/type"

printf 'USB\n' > "$fixture/ucsi-source-psy-USBC000:001/type"
printf 'System\n' > "$fixture/ucsi-source-psy-USBC000:001/scope"
printf 'Discharging\n' > "$fixture/ucsi-source-psy-USBC000:001/status"

power_out="$(KALIPWM_POWER_SUPPLY_ROOT="$fixture" bash install.sh --detect-power)"
grep -qx 'battery=BAT0' <<< "$power_out"
grep -qx 'adapter=ADP0' <<< "$power_out"
echo 'PASS installer ignores peripheral Battery-class devices and prefers mains adapter'

battery_out="$(KALIPWM_POWER_SUPPLY_ROOT="$fixture" XDG_CONFIG_HOME="$fixture/config" bash SCRIPTS/kalipwm-battery)"
[[ "$battery_out" == 'BAT 41%' ]]
echo 'PASS runtime battery module selects the system battery'

printf '\n== Hybrid GPU telemetry guard ==\n'
grep -q 'runtime_status' SCRIPTS/kalipwm-telemetry
grep -q 'KALIPWM_FORCE_GPU_TELEMETRY' SCRIPTS/kalipwm-telemetry
grep -A5 '^\[module/telemetry\]' CONFIGS/config/polybar/forest/user_modules.ini | grep -q 'interval = 15'
echo 'PASS telemetry checks runtime PM before nvidia-smi and uses a conservative polling interval'

printf '\n== Flameshot integration guard ==\n'
! grep -RInE '(^|[[:space:]])scrot([[:space:]]|$)' SCRIPTS CONFIGS/config/sxhkd >/dev/null
grep -q 'start_once flameshot flameshot' CONFIGS/config/bspwm/bspwmrc
grep -q '~/.local/bin/screenshot.sh gui' CONFIGS/config/sxhkd/sxhkdrc
grep -A1 '^ctrl + Print$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'screenshot.sh gui'
! grep -A1 '^ctrl + Print$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'launcher'
grep -q 'run_flameshot flameshot gui$' SCRIPTS/screenshot.sh
! grep -q 'flameshot gui --path' SCRIPTS/screenshot.sh
grep -q 'flameshot full --path' SCRIPTS/screenshot.sh
grep -q '^useX11LegacyScreenshot=true$' CONFIGS/config/flameshot/flameshot.ini
grep -q '^saveAfterCopy=false$' CONFIGS/config/flameshot/flameshot.ini
echo 'PASS BSPWM screenshots use native X11 capture, Ctrl+Print opens capture UI, and Ctrl+C remains clipboard-only'

printf '\n== BSPWM startup process guard ==\n'
! grep -nE 'pgrep[^\n]*\|\|[^\n]*&' CONFIGS/config/bspwm/bspwmrc >/dev/null
grep -q '^start_once()' CONFIGS/config/bspwm/bspwmrc
grep -q 'if pgrep -u "\$UID" -x "\$process"' CONFIGS/config/bspwm/bspwmrc
echo 'PASS BSPWM session startup does not leave conditional background shell wrappers'

printf '\n== BSPWM rule reload guard ==\n'
grep -q "^bspc rule -r '\*'$" CONFIGS/config/bspwm/bspwmrc
! grep -nEi '^bspc rule -a .*vmware.*desktop=' CONFIGS/config/bspwm/bspwmrc >/dev/null
echo 'PASS BSPWM reload flushes stale runtime rules and does not force VMware onto a workspace'

printf '\n== Rollback session rehydration guard ==\n'
grep -q '^rehydrate_bspwm_session()' SCRIPTS/kalipwm-state
grep -q 'pkill -USR1 -u "\$UID" -x sxhkd' SCRIPTS/kalipwm-state
grep -q 'setsid -f sxhkd -m -1' SCRIPTS/kalipwm-state
grep -A8 '^rollback()' SCRIPTS/kalipwm-state | grep -q '^  rehydrate_bspwm_session$'
echo 'PASS rollback reloads or detaches sxhkd from the invoking terminal when BSPWM stays active'

printf '\n== Uninstall session cleanup guard ==\n'
grep -q '^cleanup_stale_kalipwm_helpers()' kalipwm.sh
grep -q "pgrep -u \"\$UID\" -f 'kalipwm-display --watch'" kalipwm.sh
grep -q '\$HOME/.config/polybar/forest/config.ini' kalipwm.sh
grep -A8 '^end_stale_bspwm_session()' kalipwm.sh | grep -q '^  cleanup_stale_kalipwm_helpers$'
echo 'PASS uninstall cleans persistent KaliPWM watcher and its own Polybar before ending stale BSPWM'

printf '\n== Dynamic display reconciliation guard ==\n'
grep -q '^reconcile_bspwm()' SCRIPTS/kalipwm-display
grep -q 'bspc wm -a "\$out" "\$geometry"' SCRIPTS/kalipwm-display
grep -q 'bspc monitor "\$monitor" -r' SCRIPTS/kalipwm-display
grep -q 'bspc desktop Desktop -r' SCRIPTS/kalipwm-display
grep -q '^restart_polybar()' SCRIPTS/kalipwm-display
grep -q 'apply_all true' SCRIPTS/kalipwm-display
grep -q 'previous="\$(topology_signature)"' SCRIPTS/kalipwm-display
grep -A12 '^apply_all()' SCRIPTS/kalipwm-display | grep -q '^  return 0$'
! grep -q 'pkill -USR1 -x polybar' SCRIPTS/kalipwm-display
echo 'PASS display watcher reconciles provider-renamed outputs, stale BSPWM monitors, placeholder desktops, workspaces, and Polybar with a successful apply exit status'

printf '\n== BSPWM session lifecycle guard ==\n'
grep -q '^cleanup_bspwm_session_artifacts()' SCRIPTS/kalipwm-display
grep -A35 '^watch_layout()' SCRIPTS/kalipwm-display | grep -q '^  trap cleanup_bspwm_session_artifacts EXIT$'
grep -A35 '^watch_layout()' SCRIPTS/kalipwm-display | grep -q 'pgrep -u "\$UID" -x bspwm'
grep -A20 '^cleanup_bspwm_session_artifacts()' SCRIPTS/kalipwm-display | grep -q '\$HOME/.config/polybar/forest/config.ini'
echo 'PASS BSPWM display watcher exits with BSPWM and removes only KaliPWM-owned Polybar state before another desktop session starts'

printf '\n== Obsidian Tactical icon/font guard ==\n'
grep -q '^font-0 = "JetBrainsMono Nerd Font Mono:' CONFIGS/config/polybar/forest/config.ini
grep -q '^font-1 = "Hack Nerd Font Mono:' CONFIGS/config/polybar/forest/config.ini
! grep -qi 'feather:' CONFIGS/config/polybar/forest/config.ini
grep -q 'format-prefix = "󰓾 ' CONFIGS/config/polybar/forest/user_modules.ini
grep -q 'format-prefix = " ' CONFIGS/config/polybar/forest/user_modules.ini
grep -q 'format-prefix = "󰖩 ' CONFIGS/config/polybar/forest/user_modules.ini
grep -q 'format-prefix = "󰦝 ' CONFIGS/config/polybar/forest/user_modules.ini
grep -q 'format-prefix = "󰁹 ' CONFIGS/config/polybar/forest/user_modules.ini
echo 'PASS Polybar uses the V1 Nerd Font stack and curated Obsidian Tactical icon vocabulary'

printf '\n== Entry point ==\n'
bash kalipwm.sh --help >/dev/null
echo 'PASS kalipwm.sh --help'

printf '\nAll static checks passed.\n'
