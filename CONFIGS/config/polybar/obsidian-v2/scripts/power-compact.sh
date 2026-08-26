#!/usr/bin/env bash

ac=$(~/.config/polybar/obsidian/scripts/ac.sh 2>/dev/null)
bat=$(~/.config/polybar/obsidian/scripts/battery.sh 2>/dev/null)
percent=$(printf '%s' "$bat" | grep -oE '[0-9]+%' | tail -n1)
[ -n "$percent" ] || percent='N/A'

if printf '%s' "$ac" | grep -q '^AC 100%'; then
    printf '   %s' "$percent"
else
    printf ' %s' "$percent"
fi
