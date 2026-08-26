#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '== Resume display recovery guard ==\n'
grep -q '^topology_signature()' SCRIPTS/kalipwm-display
grep -A10 '^topology_signature()' SCRIPTS/kalipwm-display | grep -q 'output_geometry'
grep -A10 '^topology_signature()' SCRIPTS/kalipwm-display | grep -q 'inactive'
! grep -q '^display_needs_recovery()' SCRIPTS/kalipwm-display
! grep -q 'last_recovery' SCRIPTS/kalipwm-display
grep -A60 '^watch_layout()' SCRIPTS/kalipwm-display | grep -q 'if \[\[ "\$current" != "\$previous" \]\]; then'
grep -A60 '^watch_layout()' SCRIPTS/kalipwm-display | grep -q '^      apply_all true$'
grep -A60 '^watch_layout()' SCRIPTS/kalipwm-display | grep -q 'previous="$(topology_signature)"'
echo 'PASS connected-but-inactive outputs get one edge-triggered recovery attempt without an endless modeset loop'

printf '\n== Arbitrary WireGuard interface guard ==\n'
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"

cat > "$tmp/bin/wg" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == show && "${2:-}" == interfaces ]]; then
  printf 'ronin66\n'
fi
EOF

cat > "$tmp/bin/ip" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == link && "${2:-}" == show && "${3:-}" == dev && "${4:-}" == ronin66 ]]; then
  exit 0
fi
if [[ "${1:-}" == -4 && "${2:-}" == -o && "${3:-}" == addr && "${4:-}" == show && "${5:-}" == dev && "${6:-}" == ronin66 ]]; then
  printf '7: ronin66    inet 10.8.0.24/24 scope global ronin66\n'
  exit 0
fi
exit 1
EOF
chmod +x "$tmp/bin/wg" "$tmp/bin/ip"

vpn_out="$(PATH="$tmp/bin:$PATH" bash SCRIPTS/kalipwm-vpn)"
grep -Fq 'VPN ● ronin66' <<< "$vpn_out"
echo 'PASS WireGuard VPN detection does not depend on a wg* interface name'

printf '\nAll runtime regression checks passed.\n'
