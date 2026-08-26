#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

THERMAL="$TMP/thermal"
HWMON="$TMP/hwmon"
PCI="$TMP/pci"
BIN="$TMP/bin"
LOG="$TMP/nvidia.log"
mkdir -p "$THERMAL" "$HWMON" "$PCI" "$BIN"

cat > "$BIN/nvidia-smi" <<'EOF'
#!/usr/bin/env bash
printf 'called\n' >> "$KALIPWM_NVIDIA_TEST_LOG"
printf '47\n'
EOF
chmod +x "$BIN/nvidia-smi"

export PATH="$BIN:$PATH"
export KALIPWM_THERMAL_ROOT="$THERMAL"
export KALIPWM_HWMON_ROOT="$HWMON"
export KALIPWM_PCI_ROOT="$PCI"
export KALIPWM_NVIDIA_TEST_LOG="$LOG"

mkdir -p "$HWMON/hwmon0"
printf 'coretemp\n' > "$HWMON/hwmon0/name"
printf 'Package id 0\n' > "$HWMON/hwmon0/temp1_label"
printf '52000\n' > "$HWMON/hwmon0/temp1_input"
printf '2400\n' > "$HWMON/hwmon0/fan1_input"

mkdir -p "$PCI/0000:01:00.0/power"
printf '0x10de\n' > "$PCI/0000:01:00.0/vendor"
printf 'suspended\n' > "$PCI/0000:01:00.0/power/runtime_status"

out="$(bash "$ROOT/SCRIPTS/kalipwm-telemetry")"
[[ "$out" == 'TEMP CPU 52C FAN 2400RPM' ]]
[[ ! -e "$LOG" ]]

printf 'active\n' > "$PCI/0000:01:00.0/power/runtime_status"
out="$(bash "$ROOT/SCRIPTS/kalipwm-telemetry")"
[[ "$out" == 'TEMP CPU 52C GPU 47C FAN 2400RPM' ]]
[[ "$(wc -l < "$LOG")" -eq 1 ]]

rm -rf "$THERMAL"/* "$HWMON"/* "$PCI"/*
: > "$LOG"
out="$(bash "$ROOT/SCRIPTS/kalipwm-telemetry")"
[[ "$out" == 'TEMP N/A' ]]
[[ ! -s "$LOG" ]]

echo 'telemetry: PASS'
