#!/usr/bin/env bash
set -u

DIR="$HOME/.config/polybar/obsidian-v2"
modules_right=(cpu)

gpu_value="$("$HOME/.config/polybar/obsidian/scripts/gpu.sh" 2>/dev/null || true)"
if [ -n "$gpu_value" ] && [ "$gpu_value" != "N/A" ]; then
    modules_right+=(gpu)
fi

fan_value="$($DIR/scripts/fan-compact.sh 2>/dev/null || true)"
if [ -n "$fan_value" ] && [ "$fan_value" != "N/A" ]; then
    modules_right+=(fan)
fi

modules_right+=(memory audio power date sysmenu)
export KALIPWM_MODULES_RIGHT="${modules_right[*]}"

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done

polybar main -c "$DIR/config.ini" >/tmp/polybar-obsidian-v2.log 2>&1 &
disown
