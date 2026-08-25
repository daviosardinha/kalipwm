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

printf '\n== Entry point ==\n'
bash kalipwm.sh --help >/dev/null
echo 'PASS kalipwm.sh --help'

printf '\nAll static checks passed.\n'
