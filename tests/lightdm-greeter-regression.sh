#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script="$repo_root/SCRIPTS/kalipwm-lightdm"
config="$repo_root/CONFIGS/lightdm/kalipwm-obsidian.conf"
theme="$repo_root/CONFIGS/themes/KaliPWM-Obsidian"
css="$theme/gtk-3.0/gtk.css"
wallpaper="$repo_root/WALLPAPERS/obsidian/obsidian-nomad-emblem-16x9.png"

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

bash -n "$script"

[[ -s "$config" ]] || fail 'LightDM greeter fragment is missing'
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
grep -q '#login_window #login_button' "$css" || fail 'primary login action is not explicitly themed'
grep -q 'min-width: 280px;' "$css" || fail 'login card inputs are not using the refined width'
grep -q 'background-color: alpha(@obsidian_bg, 0.94);' "$css" || fail 'validated translucent card opacity changed'
grep -q 'border: 2px solid alpha(@obsidian_violet_bright, 0.95);' "$css" || fail 'validated login card border changed'
grep -q '@define-color obsidian_violet #9b7ede;' "$css" || fail 'Obsidian violet token is missing'
grep -q '@define-color obsidian_bg #0b0d12;' "$css" || fail 'Obsidian background token is missing'

grep -q 'BASE_GREETER="/etc/lightdm/lightdm-gtk-greeter.conf"' "$script" || fail 'active greeter config path changed'
grep -q 'BACKUP_GREETER="\$BACKUP_DIR/lightdm-gtk-greeter.conf.pre-kalipwm"' "$script" || fail 'greeter rollback backup path is missing'
grep -q 'sudo cp -a -- "\$BASE_GREETER" "\$BACKUP_GREETER"' "$script" || fail 'install does not preserve the exact pre-KaliPWM greeter config'
grep -Fq 'run_root install -d -m 0711 "$BACKUP_DIR"' "$script" || fail 'backup directory is not traversable for safe existence checks'
grep -Fq 'run_root chmod 0600 "$BACKUP_GREETER"' "$script" || fail 'rollback backup contents are not restricted to root'
grep -Fq 'if [ -e "$BACKUP_GREETER" ]; then' "$script" || fail 'protected rollback backup is still checked for user readability'
grep -q 'build_merged_config' "$script" || fail 'managed greeter merge function is missing'
grep -q 'sudo cp -a -- "\$BACKUP_GREETER" "\$BASE_GREETER"' "$script" || fail 'rollback does not restore the exact greeter backup'
grep -q 'run_root rm -f "\$LEGACY_OVERRIDE"' "$script" || fail 'stale ineffective conf.d override is not cleaned up'
grep -q 'No display-manager restart was performed' "$script" || fail 'script does not explicitly preserve the active session'
grep -q 'xhost +SI:localuser:lightdm' "$script" || fail 'nested preview does not grant temporary lightdm X access'
grep -q 'xhost -SI:localuser:lightdm' "$script" || fail 'nested preview does not revoke temporary lightdm X access'
grep -q 'sudo -u lightdm env DISPLAY="\$DISPLAY" lightdm --test-mode --debug' "$script" || fail 'nested LightDM test path is missing'

dry_run="$("$script" --repo "$repo_root" --dry-run install)"
grep -q 'capture exact pre-KaliPWM greeter config' <<<"$dry_run" || fail 'dry-run does not report the safety backup'
grep -q 'merge .*kalipwm-obsidian.conf.* into /etc/lightdm/lightdm-gtk-greeter.conf' <<<"$dry_run" || fail 'dry-run does not report the active config merge'
grep -q '/usr/share/themes/KaliPWM-Obsidian/gtk-3.0/gtk.css' <<<"$dry_run" || fail 'dry-run does not install GTK CSS'
grep -q '/usr/share/backgrounds/kalipwm/obsidian-login.png' <<<"$dry_run" || fail 'dry-run does not install the system-readable background'
grep -q 'chmod 0600 /var/lib/kalipwm/lightdm/lightdm-gtk-greeter.conf.pre-kalipwm' <<<"$dry_run" || fail 'dry-run does not protect the rollback backup contents'

printf '[OK] LightDM Obsidian greeter regression passed.\n'
