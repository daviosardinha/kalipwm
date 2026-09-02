#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script="$repo_root/SCRIPTS/kalipwm-lightdm"
config="$repo_root/CONFIGS/lightdm/90-kalipwm-obsidian.conf"
theme="$repo_root/CONFIGS/themes/KaliPWM-Obsidian"
css="$theme/gtk-3.0/gtk.css"
wallpaper="$repo_root/WALLPAPERS/obsidian/obsidian-nomad-emblem-16x9.png"

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

bash -n "$script"

[[ -s "$config" ]] || fail 'LightDM greeter override is missing'
[[ -s "$theme/index.theme" ]] || fail 'GTK theme index is missing'
[[ -s "$css" ]] || fail 'GTK theme CSS is missing'
[[ -s "$wallpaper" ]] || fail 'login wallpaper source is missing'

grep -q '^theme-name=KaliPWM-Obsidian$' "$config" || fail 'greeter does not select KaliPWM theme'
grep -q '^background=/usr/share/backgrounds/kalipwm/obsidian-login.png$' "$config" || fail 'greeter background destination is wrong'
grep -q '^user-background=false$' "$config" || fail 'per-user background is not disabled'
grep -q '^hide-user-image=true$' "$config" || fail 'login card still exposes the default Kali avatar'
grep -q '^indicators=.*~session.*~clock.*~power' "$config" || fail 'required session/clock/power indicators are missing'

grep -q '^#panel_window {' "$css" || fail 'panel styling is missing'
grep -q '^#login_window,' "$css" || fail 'login card styling is missing'
grep -q '#login_button' "$css" || fail 'login button styling is missing'
grep -q '@define-color obsidian_violet #9b7ede;' "$css" || fail 'Obsidian violet token is missing'
grep -q '@define-color obsidian_bg #0b0d12;' "$css" || fail 'Obsidian background token is missing'

grep -q 'GREETER_OVERRIDE="/etc/lightdm/lightdm-gtk-greeter.conf.d/90-kalipwm-obsidian.conf"' "$script" || fail 'managed greeter override path changed'
# Inspect executable mutation statements only. Do not match documentation text such
# as "The installer never edits /etc/lightdm/lightdm-gtk-greeter.conf directly".
if grep -Eq '^[[:space:]]*(run_root|sudo)[[:space:]].*/etc/lightdm/lightdm-gtk-greeter\.conf([[:space:]"'"'"']|$)' "$script"; then
    fail 'management script appears to modify Kali base greeter configuration'
fi
grep -q 'No display-manager restart was performed' "$script" || fail 'script does not explicitly preserve the active session'
grep -q 'sudo -u lightdm lightdm --test-mode --debug' "$script" || fail 'nested LightDM test path is missing'

dry_run="$("$script" --repo "$repo_root" --dry-run install)"
grep -q '/etc/lightdm/lightdm-gtk-greeter.conf.d/90-kalipwm-obsidian.conf' <<<"$dry_run" || fail 'dry-run does not install the isolated override'
grep -q '/usr/share/themes/KaliPWM-Obsidian/gtk-3.0/gtk.css' <<<"$dry_run" || fail 'dry-run does not install GTK CSS'
grep -q '/usr/share/backgrounds/kalipwm/obsidian-login.png' <<<"$dry_run" || fail 'dry-run does not install the system-readable background'

printf '[OK] LightDM Obsidian greeter regression passed.\n'
