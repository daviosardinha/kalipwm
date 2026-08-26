#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/detect" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
KaliPWM V1 read-only detection
----------------------------------------
environment=vmware
vendor=VMware, Inc.
product=VMware Virtual Platform
battery=BAT1
adapter=ACAD
backlight=none
wifi_interface=none
wired_interface=eth0
internal_display=none
connected_displays=Virtual-1
nvidia_runtime=none
----------------------------------------
OUT
EOF
chmod +x "$TMP/detect"

PROFILE="$TMP/config/kalipwm/profile.conf"
export KALIPWM_DETECTOR="$TMP/detect"
export KALIPWM_PROFILE_PATH="$PROFILE"

OUT="$(bash "$ROOT/SCRIPTS/kalipwm-profile-init" --print)"
grep -Fq 'environment=vmware' <<<"$OUT"
grep -Fq 'vendor=VMware\,\ Inc.' <<<"$OUT"
grep -Fq 'product=VMware\ Virtual\ Platform' <<<"$OUT"
grep -Fq 'wired_interface=eth0' <<<"$OUT"
grep -Fq 'connected_displays=Virtual-1' <<<"$OUT"
grep -Fq 'external_position=right' <<<"$OUT"
grep -Fq 'screenshots=scrot' <<<"$OUT"
grep -Fq 'telemetry=false' <<<"$OUT"

bash "$ROOT/SCRIPTS/kalipwm-profile-init" --write >/dev/null
[[ -f "$PROFILE" ]]
cp "$PROFILE" "$TMP/original"
printf '\noperator_edit=true\n' >> "$PROFILE"

bash "$ROOT/SCRIPTS/kalipwm-profile-init" --write >/dev/null
grep -Fq 'operator_edit=true' "$PROFILE"

bash "$ROOT/SCRIPTS/kalipwm-profile-init" --write --force >/dev/null
if grep -Fq 'operator_edit=true' "$PROFILE"; then
  echo 'forced profile replacement failed' >&2
  exit 1
fi
cmp -s "$PROFILE" "$TMP/original"

echo 'profile-generation: PASS'
