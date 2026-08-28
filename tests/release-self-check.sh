#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

required_files=(
    README.md
    ROADMAP.md
    CHANGELOG.md
    DEPENDENCIES.lock
    kalipwm.sh
    kitty-installer.sh
    SCRIPTS/kalipwm
    SCRIPTS/kalipwm-brightness
    SCRIPTS/kalipwm-release-check
    SCRIPTS/kalipwm-shell-quality
    CONFIGS/config/bspwm/bspwmrc
    CONFIGS/config/sxhkd/sxhkdrc
    CONFIGS/config/polybar/obsidian/scripts/control-center.sh
    CONFIGS/config/polybar/obsidian-v2/launch.sh
)

printf '%s\n' '== Release-critical files =='
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        printf '[FAIL] missing %s\n' "$file" >&2
        exit 1
    fi
    printf '[OK]   %s\n' "$file"
done

printf '\n%s\n' '== Release-critical shell syntax =='
bash -n kalipwm.sh
sh -n kitty-installer.sh
bash -n SCRIPTS/kalipwm
bash -n SCRIPTS/kalipwm-brightness
bash -n SCRIPTS/kalipwm-release-check
bash -n SCRIPTS/kalipwm-shell-quality
printf '%s\n' '[OK] release-critical shell syntax'

printf '\n%s\n' '== Documentation references =='
grep -Fq 'Phase 7 — Public release quality' ROADMAP.md
grep -Fq 'DEPENDENCIES.lock' README.md
grep -Fq 'Rofi-based KaliPWM Control Center' README.md
grep -Fq 'security and maintainability hardening' README.md
printf '%s\n' '[OK] release documentation anchors'

printf '\n%s\n' '== Expected wallpapers =='
wallpapers=(
    WALLPAPERS/obsidian/obsidian-city-16x9.jpg
    WALLPAPERS/obsidian/obsidian-city-ultrawide.jpg
    WALLPAPERS/obsidian/obsidian-nomad-monolith-standard.png
    WALLPAPERS/obsidian/obsidian-nomad-monolith-16x9.png
    WALLPAPERS/obsidian/obsidian-nomad-emblem-standard.png
    WALLPAPERS/obsidian/obsidian-nomad-emblem-16x9.png
)
for wallpaper in "${wallpapers[@]}"; do
    if [ ! -s "$wallpaper" ]; then
        printf '[FAIL] missing/empty wallpaper %s\n' "$wallpaper" >&2
        exit 1
    fi
done
printf '[OK] %d bundled release wallpapers\n' "${#wallpapers[@]}"

printf '\n%s\n' '== Repository hygiene =='
if git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- ':!CHANGELOG.md' ':!docs/**' >/dev/null 2>&1; then
    printf '%s\n' '[FAIL] unresolved merge-conflict marker detected' >&2
    git grep -nE '^(<<<<<<<|=======|>>>>>>>)' -- ':!CHANGELOG.md' ':!docs/**' >&2 || true
    exit 1
fi
printf '%s\n' '[OK] no unresolved merge-conflict markers'

printf '%s\n' 'release-self-check: PASS'
