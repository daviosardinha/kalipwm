#!/usr/bin/env bash

read_temp() {
    local f="$1" v
    [ -r "$f" ] || return 1
    v=$(cat "$f" 2>/dev/null) || return 1
    [ -n "$v" ] || return 1
    if [ "$v" -gt 1000 ] 2>/dev/null; then
        v=$((v / 1000))
    fi
    printf '%s' "$v"
}

cpu=""
for f in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$f" ] || continue
    v=$(read_temp "$f") || continue
    if [ -z "$cpu" ] || [ "$v" -gt "$cpu" ] 2>/dev/null; then cpu="$v"; fi
done

gpu=""
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
fi
if [ -z "$gpu" ]; then
    for hw in /sys/class/drm/card*/device/hwmon/hwmon*; do
        [ -d "$hw" ] || continue
        for f in "$hw"/temp*_input; do
            [ -r "$f" ] || continue
            gpu=$(read_temp "$f") && break 2
        done
    done
fi

cpu=${cpu:-N/A}
gpu=${gpu:-N/A}
printf 'CPU %sC GPU %sC' "$cpu" "$gpu"
