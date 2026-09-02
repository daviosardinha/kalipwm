#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script="$repo_root/CONFIGS/config/polybar/obsidian-v2/scripts/pomodoro.sh"
config="$repo_root/CONFIGS/config/polybar/obsidian-v2/config.ini"
modules="$repo_root/CONFIGS/config/polybar/obsidian-v2/modules.ini"
icons="$repo_root/CONFIGS/config/polybar/obsidian-v2/icons.ini"
launch="$repo_root/CONFIGS/config/polybar/obsidian-v2/launch.sh"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export KALIPWM_POMODORO_STATE_DIR="$tmpdir/state"
export KALIPWM_POMODORO_NO_NOTIFY=1

fail() {
    printf '[FAIL] %s\n' "$1" >&2
    exit 1
}

assert_eq() {
    local expected=$1 actual=$2 description=$3
    [[ "$actual" == "$expected" ]] || fail "$description: expected '$expected', got '$actual'"
}

bash -n "$script"
assert_eq '25m' "$("$script" status)" 'default timer'

"$script" set 1
case "$("$script" status)" in
    01:00|00:59) ;;
    *) fail 'one-minute timer did not start' ;;
esac

"$script" toggle
case "$("$script" status)" in
    'PAUSE 01:00'|'PAUSE 00:59') ;;
    *) fail 'timer did not pause' ;;
esac

"$script" toggle
"$script" reset
assert_eq '1m' "$("$script" status)" 'reset preserves selected duration'

"$script" next
assert_eq '5m' "$("$script" status)" 'next preset from custom duration'
"$script" next
assert_eq '10m' "$("$script" status)" 'next preset'
"$script" prev
assert_eq '5m' "$("$script" status)" 'previous preset'

"$script" set 17
"$script" reset
assert_eq '17m' "$("$script" status)" 'custom duration persistence'

if "$script" set 0 >/dev/null 2>&1; then
    fail 'zero-minute custom duration was accepted'
fi
if "$script" set 721 >/dev/null 2>&1; then
    fail 'custom duration above the supported maximum was accepted'
fi

mkdir -p "$KALIPWM_POMODORO_STATE_DIR"
cat > "$KALIPWM_POMODORO_STATE_DIR/pomodoro.state" <<'STATE'
selected=5
status=running
end_epoch=1
remaining=300
flash_until=0
STATE
assert_eq 'DONE' "$("$script" status)" 'expired timer completion state'
grep -q '^status=idle$' "$KALIPWM_POMODORO_STATE_DIR/pomodoro.state" || fail 'expired timer was not persisted as idle'

grep -q 'pomodoro' "$config" || fail 'fallback module list does not include pomodoro'
grep -q '^\[module/pomodoro\]$' "$modules" || fail 'Polybar pomodoro module is missing'
grep -q '^pomodoro = ' "$icons" || fail 'Pomodoro icon is missing'
grep -q 'modules_right+=(memory audio power pomodoro date sysmenu)' "$launch" || fail 'adaptive Polybar layout does not include pomodoro'

printf '[OK] Focus timer regression passed.\n'
