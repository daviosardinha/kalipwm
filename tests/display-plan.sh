#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/state"

LOG="$TMP/xrandr.log"
QUERY="$TMP/xrandr-query.txt"
PROPS="$TMP/xrandr-props.txt"
PROFILE="$TMP/profile.conf"

cat > "$TMP/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-}" in
  --query)
    cat "$KALIPWM_XRANDR_QUERY_FILE"
    exit 0
    ;;
  --props)
    cat "$KALIPWM_XRANDR_PROPS_FILE"
    exit 0
    ;;
esac
printf '%q ' "$@" >> "$KALIPWM_XRANDR_LOG"
printf '\n' >> "$KALIPWM_XRANDR_LOG"
EOF
chmod +x "$TMP/bin/xrandr"

export PATH="$TMP/bin:$PATH"
export KALIPWM_XRANDR_QUERY_FILE="$QUERY"
export KALIPWM_XRANDR_PROPS_FILE="$PROPS"
export KALIPWM_XRANDR_LOG="$LOG"
export KALIPWM_PROFILE="$PROFILE"
export KALIPWM_STATE_ROOT="$TMP/state"

# Normal two-display bare-metal fixture with a readable EDID and explicit
# profile mode/rate. The planner may propose only an already-advertised mode.
cat > "$QUERY" <<'EOF'
Screen 0: minimum 8 x 8, current 6400 x 1600, maximum 32767 x 32767
eDP-1 connected primary 2560x1600+0+0 (normal left inverted right x axis y axis)
   2560x1600     60.00*+
HDMI-1-0 connected 3840x1080+2560+0 (normal left inverted right x axis y axis)
   3840x1080    119.97*+  60.00
EOF
cat > "$PROPS" <<'EOF'
eDP-1 connected primary 2560x1600+0+0
	EDID:
		00ffffffffffff000000000000000000
HDMI-1-0 connected 3840x1080+2560+0
	EDID:
		00ffffffffffff000000000000000000
EOF
cat > "$PROFILE" <<'EOF'
environment=baremetal
internal_display=eDP-1
external_position=right
external_mode=3840x1080
external_rate=119.97
EOF

status="$(bash "$ROOT/SCRIPTS/kalipwm-display" status)"
grep -Fxq 'environment=baremetal' <<<"$status"
grep -Fxq 'connected_displays=eDP-1,HDMI-1-0' <<<"$status"
grep -Fxq 'primary_display=eDP-1' <<<"$status"
grep -Fxq 'external_display=HDMI-1-0' <<<"$status"
grep -Fxq 'external_mode=3840x1080' <<<"$status"
grep -Fxq 'external_rate=119.97' <<<"$status"

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=apply' <<<"$plan"
grep -Fxq 'display_reason=two_display_baremetal_layout' <<<"$plan"
grep -Fxq 'display_mode=3840x1080' <<<"$plan"
grep -Fxq 'display_rate=119.97' <<<"$plan"
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
find "$TMP/state/display-backups" -name xrandr-props-before.txt -type f | grep -q .

# Hybrid-GPU failure fixture observed on the Legion: connector is reported
# connected but inactive, EDID is missing, and XRandR offers generic fallback
# modes with 1024x768 marked preferred. This must never produce an apply plan.
: > "$LOG"
cat > "$QUERY" <<'EOF'
Screen 0: minimum 320 x 200, current 2560 x 1600, maximum 16384 x 16384
eDP-1 connected primary 2560x1600+0+0 (normal left inverted right x axis y axis)
   2560x1600    240.00*+  60.00
HDMI-1-0 connected (normal left inverted right x axis y axis)
   1024x768      60.00 +
   1600x900      59.82
EOF
cat > "$PROPS" <<'EOF'
eDP-1 connected primary 2560x1600+0+0
	EDID:
		00ffffffffffff000000000000000000
HDMI-1-0 connected
	PRIME Synchronization: 0
EOF
cat > "$PROFILE" <<'EOF'
environment=baremetal
internal_display=eDP-1
external_position=right
external_mode=auto
external_rate=auto
EOF

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=noop' <<<"$plan"
grep -Fxq 'display_reason=external_edid_unavailable' <<<"$plan"
! grep -Fq 'display_command=' <<<"$plan"
bash "$ROOT/SCRIPTS/kalipwm-display" apply --confirm >/dev/null
[[ ! -s "$LOG" ]]

# An explicit desired native mode is also fail-closed if the connector does not
# currently advertise that mode. The helper never invents modelines.
cat > "$PROPS" <<'EOF'
eDP-1 connected primary 2560x1600+0+0
	EDID:
		00ffffffffffff000000000000000000
HDMI-1-0 connected
	EDID:
		00ffffffffffff000000000000000000
EOF
cat > "$PROFILE" <<'EOF'
environment=baremetal
internal_display=eDP-1
external_position=right
external_mode=3840x1080
external_rate=119.97
EOF

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=noop' <<<"$plan"
grep -Fxq 'display_reason=requested_external_mode_unavailable' <<<"$plan"
! grep -Fq 'display_command=' <<<"$plan"

# VMware remains an unconditional display no-op even when a virtual output is
# active and has no EDID information in the fixture.
: > "$LOG"
cat > "$QUERY" <<'EOF'
Screen 0: minimum 320 x 200, current 2310 x 1416, maximum 8192 x 8192
Virtual-1 connected primary 2310x1416+0+0 (normal left inverted right x axis y axis)
   2310x1416     60.00*+
Virtual-2 disconnected (normal left inverted right x axis y axis)
EOF
: > "$PROPS"
cat > "$PROFILE" <<'EOF'
environment=vmware
internal_display=none
external_position=right
external_mode=auto
external_rate=auto
EOF

plan="$(bash "$ROOT/SCRIPTS/kalipwm-display" plan)"
grep -Fxq 'display_action=noop' <<<"$plan"
grep -Fxq 'display_reason=virtual_display_managed_by_guest_tools' <<<"$plan"
bash "$ROOT/SCRIPTS/kalipwm-display" apply --confirm >/dev/null
[[ ! -s "$LOG" ]]

echo 'display-plan: PASS'
