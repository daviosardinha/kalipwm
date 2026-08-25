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

printf '\n== Entry point ==\n'
bash kalipwm.sh --help >/dev/null
echo 'PASS kalipwm.sh --help'

printf '\nAll static checks passed.\n'
