#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/backlight/intel_backlight" "$TMP/config/kalipwm"

cat > "$TMP/bin/wpctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == get-volume ]]; then
  printf 'Volume: 0.42\n'
else
  printf '%s\n' "$*" >> "${KALIPWM_TEST_LOG:?}"
fi
EOF
chmod +x "$TMP/bin/wpctl"

cat > "$TMP/bin/brightnessctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${KALIPWM_TEST_LOG:?}"
EOF
chmod +x "$TMP/bin/brightnessctl"

cat > "$TMP/bin/dunstify" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${KALIPWM_TEST_NOTIFY_LOG:?}"
EOF
chmod +x "$TMP/bin/dunstify"

printf 'backlight=intel_backlight\n' > "$TMP/config/kalipwm/profile.conf"
printf '400\n' > "$TMP/backlight/intel_backlight/brightness"
printf '1000\n' > "$TMP/backlight/intel_backlight/max_brightness"

export PATH="$TMP/bin:$PATH"
export XDG_CONFIG_HOME="$TMP/config"
export KALIPWM_BACKLIGHT_ROOT="$TMP/backlight"
export KALIPWM_TEST_LOG="$TMP/actions.log"
export KALIPWM_TEST_NOTIFY_LOG="$TMP/notify.log"

AUDIO="$(bash "$ROOT/SCRIPTS/kalipwm-audio" status)"
[[ "$AUDIO" == 'AUDIO 42%' ]]
bash "$ROOT/SCRIPTS/kalipwm-audio" down
grep -Fq 'set-volume @DEFAULT_AUDIO_SINK@ 5%-' "$TMP/actions.log"

BRIGHT="$(bash "$ROOT/SCRIPTS/kalipwm-brightness" status)"
[[ "$BRIGHT" == 'BRIGHTNESS 40% intel_backlight' ]]
bash "$ROOT/SCRIPTS/kalipwm-brightness" up
grep -Fq -- '-q -d intel_backlight set +5%' "$TMP/actions.log"

cat > "$TMP/audio-helper" <<'EOF'
#!/usr/bin/env bash
printf 'AUDIO 42%%\n'
EOF
cat > "$TMP/brightness-helper" <<'EOF'
#!/usr/bin/env bash
printf 'BRIGHTNESS 40%% intel_backlight\n'
EOF
chmod +x "$TMP/audio-helper" "$TMP/brightness-helper"
export KALIPWM_AUDIO_HELPER="$TMP/audio-helper"
export KALIPWM_BRIGHTNESS_HELPER="$TMP/brightness-helper"

bash "$ROOT/SCRIPTS/kalipwm-osd" volume
bash "$ROOT/SCRIPTS/kalipwm-osd" brightness
grep -Fq 'Volume 42%' "$TMP/notify.log"
grep -Fq 'Brightness 40%' "$TMP/notify.log"

echo 'audio-brightness-osd: PASS'
