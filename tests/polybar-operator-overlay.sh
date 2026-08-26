#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
CONFIG_HOME="$HOME_DIR/.config"
FOREST="$CONFIG_HOME/polybar/forest"
PROFILE_DIR="$CONFIG_HOME/kalipwm"
STATE="$TMP/state"
mkdir -p "$FOREST" "$PROFILE_DIR" "$HOME_DIR/.local/bin"

write_upstream_fixture() {
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

  cat > "$FOREST/modules.ini" <<'EOF'
[module/workspaces]
label-empty = 󰯈
label-empty-foreground = ${color.lime} # color.foreground para dejar en blanco
EOF
}

set_telemetry() {
  printf 'telemetry=%s\n' "$1" > "$PROFILE_DIR/profile.conf"
}

run_overlay() {
  HOME="$HOME_DIR" \
  KALIPWM_CONFIG_HOME="$CONFIG_HOME" \
  KALIPWM_STATE_ROOT="$STATE" \
  bash "$ROOT/SCRIPTS/kalipwm-polybar-operator-overlay" "$@"
}

# Base operator overlay: telemetry disabled.
write_upstream_fixture
set_telemetry false
run_overlay apply >/dev/null

grep -Fxq 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini"
grep -Fxq 'modules-left = launcher sep kalipwm-network kalipwm-vpn kalipwm-target' "$FOREST/config.ini"
grep -Fxq 'modules-right = cpu memory kalipwm-audio kalipwm-battery date sep sysmenu' "$FOREST/config.ini"
[[ "$(grep -Fxc 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini")" -eq 1 ]]
grep -Fxq 'label-empty-foreground = ${color.lime}' "$FOREST/modules.ini"
! grep -Fq '# color.foreground para dejar en blanco' "$FOREST/modules.ini"

for module in kalipwm-network kalipwm-vpn kalipwm-target kalipwm-audio kalipwm-telemetry kalipwm-battery; do
  grep -Fq "[module/$module]" "$FOREST/kalipwm-operator.ini"
done

grep -Fxq 'exec = ~/.config/polybar/forest/scripts/kalipwm-audio status' "$FOREST/kalipwm-operator.ini"
grep -Fxq 'exec = ~/.config/polybar/forest/scripts/kalipwm-telemetry' "$FOREST/kalipwm-operator.ini"

for helper in kalipwm-network kalipwm-vpn kalipwm-audio kalipwm-telemetry kalipwm-battery target.sh; do
  [[ -x "$FOREST/scripts/$helper" ]]
done
[[ -L "$HOME_DIR/.local/bin/target" ]]

grep -Fq 'operator_overlay=active' < <(run_overlay status)
grep -Fq 'workspace_color_fix=active' < <(run_overlay status)
grep -Fq 'telemetry=disabled' < <(run_overlay status)

# Enabling telemetry in the hardware profile should migrate an already-active
# overlay without removal/reinstall and remain idempotent.
set_telemetry true
run_overlay apply >/dev/null
grep -Fxq 'modules-right = cpu memory kalipwm-audio kalipwm-telemetry kalipwm-battery date sep sysmenu' "$FOREST/config.ini"
grep -Fq 'telemetry=enabled' < <(run_overlay status)
grep -Fq 'operator_overlay=active' < <(run_overlay status)

cp "$FOREST/config.ini" "$TMP/after-telemetry-config"
cp "$FOREST/modules.ini" "$TMP/after-telemetry-modules"
run_overlay apply >/dev/null
cmp -s "$FOREST/config.ini" "$TMP/after-telemetry-config"
cmp -s "$FOREST/modules.ini" "$TMP/after-telemetry-modules"
[[ "$(grep -Fxc 'include-file = ~/.config/polybar/forest/kalipwm-operator.ini' "$FOREST/config.ini")" -eq 1 ]]

# Disabling telemetry again must remove only that right-side module while
# preserving the operator overlay.
set_telemetry false
run_overlay apply >/dev/null
grep -Fxq 'modules-right = cpu memory kalipwm-audio kalipwm-battery date sep sysmenu' "$FOREST/config.ini"
grep -Fq 'telemetry=disabled' < <(run_overlay status)
grep -Fq 'operator_overlay=active' < <(run_overlay status)

run_overlay remove >/dev/null
grep -Fxq 'modules-left = launcher sep wired-network vpn target' "$FOREST/config.ini"
grep -Fxq 'modules-right = cpu memory volume date sep sysmenu' "$FOREST/config.ini"
grep -Fxq 'label-empty-foreground = ${color.lime} # color.foreground para dejar en blanco' "$FOREST/modules.ini"
! grep -Fq 'kalipwm-operator.ini' "$FOREST/config.ini"
[[ ! -e "$FOREST/kalipwm-operator.ini" ]]
grep -Fq 'operator_overlay=inactive' < <(run_overlay status)

# Upgrade regression: the first operator overlay shipped with upstream `volume`
# still present. A subsequent telemetry-enabled apply must migrate it directly.
cat > "$FOREST/config.ini" <<'EOF'
include-file = ~/.config/polybar/forest/bars.ini
include-file = ~/.config/polybar/forest/colors.ini
include-file = ~/.config/polybar/forest/modules.ini
include-file = ~/.config/polybar/forest/user_modules.ini
include-file = ~/.config/polybar/forest/kalipwm-operator.ini

[bar/main]
modules-left = launcher sep kalipwm-network kalipwm-vpn kalipwm-target
modules-center = workspaces
modules-right = cpu memory volume kalipwm-battery date sep sysmenu
EOF
cat > "$FOREST/modules.ini" <<'EOF'
[module/workspaces]
label-empty = 󰯈
label-empty-foreground = ${color.lime} # color.foreground para dejar en blanco
EOF
printf '; legacy overlay\n' > "$FOREST/kalipwm-operator.ini"
set_telemetry true

run_overlay apply >/dev/null
grep -Fxq 'modules-right = cpu memory kalipwm-audio kalipwm-telemetry kalipwm-battery date sep sysmenu' "$FOREST/config.ini"
grep -Fxq 'label-empty-foreground = ${color.lime}' "$FOREST/modules.ini"
grep -Fq '[module/kalipwm-audio]' "$FOREST/kalipwm-operator.ini"
grep -Fq '[module/kalipwm-telemetry]' "$FOREST/kalipwm-operator.ini"
grep -Fq 'telemetry=enabled' < <(run_overlay status)
grep -Fq 'operator_overlay=active' < <(run_overlay status)

echo 'polybar-operator-overlay: PASS'
