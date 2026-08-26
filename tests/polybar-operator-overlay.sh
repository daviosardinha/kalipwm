#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
CONFIG_HOME="$HOME_DIR/.config"
FOREST="$CONFIG_HOME/polybar/forest"
STATE="$TMP/state"
mkdir -p "$FOREST" "$HOME_DIR/.local/bin"

cat > "$FOREST/config.ini" <<'EOF'
include-file = ~/.config/polybar/forest/bars.ini
include-file = ~/.config/polybar/forest/colors.ini
include-file = ~/.config/polybar/forest/modules.ini
include-file = ~/.config/polybar/forest/user_modules.ini

[bar/main]
modules-left = launcher sep wired-network vpn target
modules-center = workspaces
modules-right = cpu memory volume date sep sysmenu
EOF

run_overlay() {
  HOME="$HOME_DIR" \
  KALIPWM_CONFIG_HOME="$CONFIG_HOME" \
  KALIPWM_STATE_ROOT="$STATE" \
  bash "$ROOT/SCRIPTS/kalipwm-polybar-operator-overlay" "$@"
}

run_overlay apply >/dev/null

grep -Fxq 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini"
grep -Fxq 'modules-left = launcher sep kalipwm-network kalipwm-vpn kalipwm-target' "$FOREST/config.ini"
grep -Fxq 'modules-right = cpu memory volume kalipwm-battery date sep sysmenu' "$FOREST/config.ini"
[[ "$(grep -Fxc 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini")" -eq 1 ]]

for module in kalipwm-network kalipwm-vpn kalipwm-target kalipwm-battery; do
  grep -Fq "[module/$module]" "$FOREST/kalipwm-operator.ini"
done

for helper in kalipwm-network kalipwm-vpn kalipwm-battery target.sh; do
  [[ -x "$FOREST/scripts/$helper" ]]
done
[[ -L "$HOME_DIR/.local/bin/target" ]]

cp "$FOREST/config.ini" "$TMP/after-first"
run_overlay apply >/dev/null
cmp -s "$FOREST/config.ini" "$TMP/after-first"
[[ "$(grep -Fxc 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini")" -eq 1 ]]
grep -Fq 'operator_overlay=active' < <(run_overlay status)

run_overlay remove >/dev/null
grep -Fxq 'modules-left = launcher sep wired-network vpn target' "$FOREST/config.ini"
grep -Fxq 'modules-right = cpu memory volume date sep sysmenu' "$FOREST/config.ini"
! grep -Fq 'kalipwm-operator.ini' "$FOREST/config.ini"
[[ ! -e "$FOREST/kalipwm-operator.ini" ]]
grep -Fq 'operator_overlay=inactive' < <(run_overlay status)

echo 'polybar-operator-overlay: PASS'
