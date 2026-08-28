#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

SXHKD="$ROOT/CONFIGS/config/sxhkd/sxhkdrc"
MEDIA="$ROOT/CONFIGS/config/polybar/obsidian/scripts/media-keys.sh"
CONTROL="$ROOT/CONFIGS/config/polybar/obsidian/scripts/control-center.sh"
BRIGHTNESS="$ROOT/SCRIPTS/kalipwm-brightness"
OSD="$ROOT/SCRIPTS/kalipwm-osd"

printf '%s\n' '== Brightness binding guard =='
grep -Fq 'XF86MonBrightness{Up,Down}' "$SXHKD"
grep -Fq 'bash ~/.config/polybar/forest/scripts/kalipwm-brightness {up,down} && bash ~/.config/polybar/forest/scripts/kalipwm-osd brightness' "$SXHKD"
grep -Fq '"$MEDIA_KEYS" brightness-up' "$CONTROL"
grep -Fq '"$MEDIA_KEYS" brightness-down' "$CONTROL"
printf '%s\n' '[OK] physical XF86 brightness events and Control Center routing are preserved'

mkdir -p "$TMP/bin" "$TMP/backlight/intel_backlight" "$TMP/config/kalipwm" "$TMP/home/.config/polybar/forest/scripts"
printf 'backlight=intel_backlight\n' > "$TMP/config/kalipwm/profile.conf"
printf '400\n' > "$TMP/backlight/intel_backlight/brightness"
printf '1000\n' > "$TMP/backlight/intel_backlight/max_brightness"

cat > "$TMP/bin/brightnessctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${KALIPWM_TEST_ACTION_LOG:?}"
EOF
chmod +x "$TMP/bin/brightnessctl"

cat > "$TMP/bin/dunstify" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${KALIPWM_TEST_NOTIFY_LOG:?}"
EOF
chmod +x "$TMP/bin/dunstify"

export PATH="$TMP/bin:$PATH"
export XDG_CONFIG_HOME="$TMP/config"
export KALIPWM_BACKLIGHT_ROOT="$TMP/backlight"
export KALIPWM_TEST_ACTION_LOG="$TMP/actions.log"
export KALIPWM_TEST_NOTIFY_LOG="$TMP/notify.log"

printf '%s\n' '== Brightness helper behavior =='
status="$(bash "$BRIGHTNESS" status)"
[[ "$status" == 'BRIGHTNESS 40% intel_backlight' ]]
bash "$BRIGHTNESS" up
bash "$BRIGHTNESS" down
grep -Fq -- '-q -d intel_backlight set +5%' "$TMP/actions.log"
grep -Fq -- '-q -d intel_backlight set 5%-' "$TMP/actions.log"
printf '%s\n' '[OK] validated backlight selection and brightnessctl commands are preserved'

printf '%s\n' '== Brightness OSD =='
export KALIPWM_BRIGHTNESS_HELPER="$BRIGHTNESS"
bash "$OSD" brightness
grep -Fq 'Brightness 40%' "$TMP/notify.log"
printf '%s\n' '[OK] brightness OSD remains wired to helper status'

cat > "$TMP/home/.config/polybar/forest/scripts/kalipwm-brightness" <<'EOF'
#!/usr/bin/env bash
printf 'brightness:%s\n' "${1:-}" >> "${KALIPWM_TEST_MEDIA_LOG:?}"
EOF
cat > "$TMP/home/.config/polybar/forest/scripts/kalipwm-osd" <<'EOF'
#!/usr/bin/env bash
printf 'osd:%s\n' "${1:-}" >> "${KALIPWM_TEST_MEDIA_LOG:?}"
EOF
chmod +x "$TMP/home/.config/polybar/forest/scripts/kalipwm-brightness" "$TMP/home/.config/polybar/forest/scripts/kalipwm-osd"
export KALIPWM_TEST_MEDIA_LOG="$TMP/media.log"

printf '%s\n' '== Obsidian media helper delegation =='
HOME="$TMP/home" bash "$MEDIA" brightness-up
HOME="$TMP/home" bash "$MEDIA" brightness-down
grep -Fq 'brightness:up' "$TMP/media.log"
grep -Fq 'brightness:down' "$TMP/media.log"
[[ "$(grep -Fc 'osd:brightness' "$TMP/media.log")" -eq 2 ]]
printf '%s\n' '[OK] Obsidian brightness actions delegate to the validated helper and OSD'

printf '%s\n' 'brightness-regression: PASS'
