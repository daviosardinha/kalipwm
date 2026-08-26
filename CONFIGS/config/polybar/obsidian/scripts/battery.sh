#!/usr/bin/env bash

bat=""
for path in /sys/class/power_supply/BAT*; do
    [ -d "$path" ] || continue
    bat="$path"
    break
done

if [ -z "$bat" ]; then
    printf 'BAT N/A'
    exit 0
fi

name="${bat##*/}"
cap=$(cat "$bat/capacity" 2>/dev/null || printf '?')
status=$(cat "$bat/status" 2>/dev/null || printf 'Unknown')

case "$status" in
    Full) printf 'FULL %s %s%%' "$name" "$cap" ;;
    Charging) printf 'CHG %s %s%%' "$name" "$cap" ;;
    Discharging) printf '%s %s%%' "$name" "$cap" ;;
    *) printf '%s %s%%' "$name" "$cap" ;;
esac
