#!/usr/bin/env bash

max=0
found=0

for f in /sys/class/hwmon/hwmon*/fan*_input; do
    [ -r "$f" ] || continue
    value=$(/usr/bin/cat "$f" 2>/dev/null)
    [[ "$value" =~ ^[0-9]+$ ]] || continue
    found=1
    if [ "$value" -gt "$max" ]; then
        max="$value"
    fi
done

if [ "$found" -eq 0 ]; then
    printf 'N/A'
else
    printf '%sRPM' "$max"
fi
