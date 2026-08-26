#!/usr/bin/env bash

usage=$(~/.config/polybar/obsidian/scripts/gpu.sh 2>/dev/null)
temp=$(~/.config/polybar/obsidian/scripts/thermal.sh 2>/dev/null | sed -n 's/.*GPU \([^C ]*\)C.*/\1/p')
usage=${usage:-N/A}

if [ -n "$temp" ] && [ "$temp" != "N/A" ]; then
    printf '%s %s°' "$usage" "$temp"
else
    printf '%s' "$usage"
fi
