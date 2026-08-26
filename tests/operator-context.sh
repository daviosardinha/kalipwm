#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# target.sh must keep state user-scoped and preserve the simple upstream output.
export XDG_RUNTIME_DIR="$TMP/runtime"
mkdir -p "$XDG_RUNTIME_DIR"

OUT="$(bash "$ROOT/SCRIPTS/target.sh")"
[[ "$OUT" == 'No Target' ]]

bash "$ROOT/SCRIPTS/target.sh" 172.16.18.10
[[ "$(bash "$ROOT/SCRIPTS/target.sh")" == '172.16.18.10' ]]
[[ -f "$XDG_RUNTIME_DIR/kalipwm-target-${UID}" ]]

bash "$ROOT/SCRIPTS/target.sh" clear
[[ "$(bash "$ROOT/SCRIPTS/target.sh")" == 'No Target' ]]

# Generic WireGuard discovery must support arbitrary interface names such as
# ronin66 rather than assuming wg0/wg1.
mkdir -p "$TMP/bin" "$TMP/net/ronin66"
printf 'unknown\n' > "$TMP/net/ronin66/operstate"

cat > "$TMP/bin/wg" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == show && "${2:-}" == interfaces ]]; then
  echo ronin66
fi
EOF
chmod +x "$TMP/bin/wg"

cat > "$TMP/bin/ip" <<'EOF'
#!/usr/bin/env bash
if [[ "$*" == '-4 -o addr show dev ronin66 scope global' ]]; then
  echo '9: ronin66    inet 10.66.66.2/24 scope global ronin66'
  exit 0
fi
if [[ "$*" == 'link show dev ronin66' ]]; then
  exit 0
fi
exit 1
EOF
chmod +x "$TMP/bin/ip"

OUT="$(PATH="$TMP/bin:$PATH" KALIPWM_NET_ROOT="$TMP/net" bash "$ROOT/SCRIPTS/kalipwm-vpn")"
[[ "$OUT" == 'VPN ON ronin66 10.66.66.2' ]]

echo 'operator-context: PASS'
