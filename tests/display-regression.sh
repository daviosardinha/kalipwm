#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="$ROOT/CONFIGS/config/bspwm/scripts/kalipwm-display.sh"
TMP="$(mktemp -d /tmp/kalipwm-display-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/bin"
XRANDR_LOG="$TMP/xrandr.log"
BSPC_LOG="$TMP/bspc.log"
QUERY_FILE="$TMP/xrandr-query"
MONITORS_FILE="$TMP/bspc-monitors"

cat >"$TMP/bin/xrandr" <<'EOF'
#!/usr/bin/env bash
set -eu
case "${1:-}" in
    --query|--current)
        cat "$KALIPWM_TEST_XRANDR_QUERY"
        ;;
    --listproviders)
        printf '%s\n' 'Providers: number : 1'
        ;;
    *)
        printf '%s\n' "$*" >>"$KALIPWM_TEST_XRANDR_LOG"
        ;;
esac
EOF

cat >"$TMP/bin/bspc" <<'EOF'
#!/usr/bin/env bash
set -eu
if [ "$#" -eq 3 ] && [ "$1" = "query" ] && [ "$2" = "-M" ] && [ "$3" = "--names" ]; then
    cat "$KALIPWM_TEST_BSPC_MONITORS"
    exit 0
fi
printf '%s\n' "$*" >>"$KALIPWM_TEST_BSPC_LOG"
EOF

chmod +x "$TMP/bin/xrandr" "$TMP/bin/bspc"

export PATH="$TMP/bin:$PATH"
export DISPLAY=:99
export KALIPWM_TEST_XRANDR_QUERY="$QUERY_FILE"
export KALIPWM_TEST_XRANDR_LOG="$XRANDR_LOG"
export KALIPWM_TEST_BSPC_MONITORS="$MONITORS_FILE"
export KALIPWM_TEST_BSPC_LOG="$BSPC_LOG"

printf '%s\n' '== External output activation =='
cat >"$QUERY_FILE" <<'EOF'
Screen 0: minimum 8 x 8, current 1920 x 1080, maximum 32767 x 32767
eDP-1 connected primary 1920x1080+0+0 (normal left inverted right x axis y axis)
HDMI-1 connected (normal left inverted right x axis y axis)
EOF
: >"$XRANDR_LOG"
bash "$HELPER" auto

grep -Fxq -- '--output HDMI-1 --auto --right-of eDP-1' "$XRANDR_LOG"
if grep -Fq -- '--output eDP-1 --auto' "$XRANDR_LOG"; then
    printf '%s\n' '[FAIL] active internal display was reconfigured unexpectedly' >&2
    exit 1
fi
printf '%s\n' '[OK] inactive external display is activated to the right of the active panel'

printf '\n%s\n' '== Preserve external-only layout =='
cat >"$QUERY_FILE" <<'EOF'
Screen 0: minimum 8 x 8, current 2560 x 1440, maximum 32767 x 32767
eDP-1 connected (normal left inverted right x axis y axis)
HDMI-1 connected primary 2560x1440+0+0 (normal left inverted right x axis y axis)
EOF
: >"$XRANDR_LOG"
bash "$HELPER" auto

if [ -s "$XRANDR_LOG" ]; then
    printf '%s\n' '[FAIL] deliberate external-only layout was modified' >&2
    cat "$XRANDR_LOG" >&2
    exit 1
fi
printf '%s\n' '[OK] disabled internal panel remains disabled when an external display is active'

printf '\n%s\n' '== BSPWM workspace distribution =='
printf '%s\n' 'eDP-1' 'HDMI-1' >"$MONITORS_FILE"
: >"$BSPC_LOG"
bash "$HELPER" workspaces

grep -Fxq -- 'monitor eDP-1 -d I II III IV V' "$BSPC_LOG"
grep -Fxq -- 'monitor HDMI-1 -d VI VII VIII IX X' "$BSPC_LOG"
printf '%s\n' '[OK] ten KaliPWM workspaces are split evenly across two monitors'

printf '\n%s\n' '== Managed multi-monitor architecture =='
grep -Fq '"$DISPLAY_HELPER" auto' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq '"$DISPLAY_HELPER" reconcile' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq '"$DISPLAY_HELPER" workspaces' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq '"$DISPLAY_HELPER" watch' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq 'bspc config remove_unplugged_monitors true' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq 'bspc config remove_disabled_monitors true' "$ROOT/CONFIGS/config/bspwm/bspwmrc"
grep -Fq 'reconcile_bspwm_monitors()' "$HELPER"
grep -Fq 'bspc desktop "$desktop" --to-monitor "$anchor"' "$HELPER"
grep -Fq 'bspc monitor "$monitor" --remove' "$HELPER"
grep -Fq 'bspc wm --add-monitor "$output" "$geometry"' "$HELPER"
grep -Fq 'watch_hotplug()' "$HELPER"
grep -Fq 'flock -n 9' "$HELPER"
grep -Fq 'bspc wm -r' "$HELPER"
grep -Fq 'monitor = ${env:MONITOR:}' "$ROOT/CONFIGS/config/polybar/obsidian-v2/config.ini"
grep -Fq 'polybar --list-monitors' "$ROOT/CONFIGS/config/polybar/obsidian-v2/launch.sh"
grep -Fq 'MONITOR="$monitor" polybar main' "$ROOT/CONFIGS/config/polybar/obsidian-v2/launch.sh"
grep -Fq 'arandr x11-xserver-utils' "$ROOT/kalipwm.sh"
grep -Fq 'connected:%s-active' "$ROOT/SCRIPTS/kalipwm-release-check"
printf '%s\n' '[OK] startup, Polybar, installer and release validation are multi-monitor aware'

printf '%s\n' 'display-regression: PASS'
