#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state"

LOG="$TMP/xrandr.log"
QUERY="$TMP/xrandr-query.txt"
PROFILE="$TMP/profile.conf"

cat > "$TMP/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${1:-}" == --query ]]; then
  cat "$KALIPWM_XRANDR_QUERY_FILE"
  exit 0
fi
printf '%q ' "$@" >> "$KALIPWM_XRANDR_LOG"
printf '\n' >> "$KALIPWM_XRANDR_LOG"
EOF
chmod +x "$TMP/bin/xrandr"

export PATH="$TMP/bin:$PATH"
export KALIPWM_XRANDR_QUERY_FILE="$QUERY"
export KALIPWM_XRANDR_LOG="$LOG"
export KALIPWM_PROFILE="$PROFILE"
export KALIPWM_STATE_ROOT="$TMP/state"

cat > "$QUERY" <<'EOF'
Screen 0: minimum 8 x 8, current 6400 x 1600, maximum 32767 x 32767
eDP-1 connected primary 2560x1600+0+0 (normal left inverted right x axis y axis)
   2560x1600     60.00*+
HDMI-1-0 connected 3840x1080+2560+0 (normal left inverted right x axis y axis)
   3840x1080    119.97*+  60.00
EOF
cat > "$PROFILE" <<'EOF'
environment=baremetal
internal_display=eDP-1
external_position=right
EOF

status="$(bash "$ROOT/SCRIPTS/kalipwm-display" status)"
grep -Fxq 'environment=baremetal' <<<"$status"
grep -Fxq 'connected_displays=eDP-1,HDMI-1-0' <<<"$status"
grep -Fxq 'primary_display=eDP-1' <<<"$status"
grep -Fxq 'external_display=HDMI-1-0' <<<"$status"

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=apply' <<<"$plan"
grep -Fxq 'display_reason=two_display_baremetal_layout' <<<"$plan"
grep -Fq -- '--output eDP-1 --primary --output HDMI-1-0 --mode 3840x1080 --rate 119.97 --right-of eDP-1' <<<"$plan"

if bash "$ROOT/SCRIPTS/kalipwm-display" apply >/dev/null 2>&1; then
  echo 'display apply succeeded without explicit confirmation' >&2
  exit 1
fi
[[ ! -s "$LOG" ]]

bash "$ROOT/SCRIPTS/kalipwm-display" apply --confirm >/dev/null
[[ -s "$LOG" ]]
grep -Fq -- '--output eDP-1 --primary --output HDMI-1-0 --mode 3840x1080 --rate 119.97 --right-of eDP-1' "$LOG"
find "$TMP/state/display-backups" -name xrandr-before.txt -type f | grep -q .

: > "$LOG"
cat > "$QUERY" <<'EOF'
Screen 0: minimum 320 x 200, current 2310 x 1416, maximum 8192 x 8192
Virtual-1 connected primary 2310x1416+0+0 (normal left inverted right x axis y axis)
   2310x1416     60.00*+
Virtual-2 disconnected (normal left inverted right x axis y axis)
EOF
cat > "$PROFILE" <<'EOF'
environment=vmware
internal_display=none
external_position=right
EOF

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=noop' <<<"$plan"
grep -Fxq 'display_reason=virtual_display_managed_by_guest_tools' <<<"$plan"
bash "$ROOT/SCRIPTS/kalipwm-display" apply --confirm >/dev/null
[[ ! -s "$LOG" ]]

echo 'display-plan: PASS'
