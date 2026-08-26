#!/usr/bin/env bash

values=()
for f in /sys/class/hwmon/hwmon*/fan*_input; do
    [ -r "$f" ] || continue
    v=$(cat "$f" 2>/dev/null)
    [ -n "$v" ] || continue
    values+=("$v")
done

if [ "${#values[@]}" -eq 0 ]; then
    printf 'N/A'
    exit 0
fi

out=""
for v in "${values[@]}"; do
    if [ -n "$out" ]; then out+="/"; fi
    out+="$v"
done
printf '%sRPM' "$out"
