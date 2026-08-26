#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin" "$TMP/net/wlan0/wireless" "$TMP/net/eth0" "$TMP/power/BAT0" "$TMP/power/ADP0"
printf 'up\n' > "$TMP/net/wlan0/operstate"
printf 'down\n' > "$TMP/net/eth0/operstate"

cat > "$TMP/profile.conf" <<'EOF'
wifi_interface=wlan0
wired_interface=eth0
battery=WRONG
adapter=ADP0
EOF

cat > "$TMP/bin/ip" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  '-4 route show default')
    echo 'default dev ronin66 proto static'
    ;;
  '-4 -o addr show dev wlan0 scope global')
    echo '4: wlan0    inet 192.168.1.50/24 brd 192.168.1.255 scope global wlan0'
    ;;
  '-4 -o addr show dev eth0 scope global')
    ;;
esac
EOF
chmod +x "$TMP/bin/ip"

export PATH="$TMP/bin:$PATH"
export KALIPWM_PROFILE_PATH="$TMP/profile.conf"
export KALIPWM_NET_ROOT="$TMP/net"

NETWORK="$(bash "$ROOT/SCRIPTS/kalipwm-network")"
[[ "$NETWORK" == 'WLAN wlan0 192.168.1.50' ]] || {
  echo "unexpected network output: $NETWORK" >&2
  exit 1
}

printf 'Battery\n' > "$TMP/power/BAT0/type"
printf 'System\n' > "$TMP/power/BAT0/scope"
printf '1\n' > "$TMP/power/BAT0/present"
printf '73\n' > "$TMP/power/BAT0/capacity"
printf 'Charging\n' > "$TMP/power/BAT0/status"
printf 'Mains\n' > "$TMP/power/ADP0/type"
printf '1\n' > "$TMP/power/ADP0/online"

export KALIPWM_POWER_SUPPLY_ROOT="$TMP/power"

POWER="$(bash "$ROOT/SCRIPTS/kalipwm-battery")"
[[ "$POWER" == 'AC 73% CHG BAT0' ]] || {
  echo "unexpected AC battery output: $POWER" >&2
  exit 1
}

printf '0\n' > "$TMP/power/ADP0/online"
printf 'Discharging\n' > "$TMP/power/BAT0/status"
POWER="$(bash "$ROOT/SCRIPTS/kalipwm-battery")"
[[ "$POWER" == 'BAT 73% DIS BAT0' ]] || {
  echo "unexpected battery output: $POWER" >&2
  exit 1
}

echo 'network-battery: PASS'
