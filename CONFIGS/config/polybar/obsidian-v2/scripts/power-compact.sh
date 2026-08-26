#!/usr/bin/env bash

ac=$(~/.config/polybar/obsidian/scripts/ac.sh 2>/dev/null)
bat=$(~/.config/polybar/obsidian/scripts/battery.sh 2>/dev/null)
percent=$(printf '%s' "$bat" | grep -oE '[0-9]+%' | tail -n1)
[ -n "$percent" ] || percent='N/A'

icon_on='%{F#9B7EDE}%{T4}'
icon_off='%{T-}%{F-}'

if printf '%s' "$ac" | grep -q '^AC 100%'; then
    printf '%s%s %s%s %s' "$icon_on" "$icon_off" "$icon_on" "$icon_off" "$percent"
else
    printf '%s%s %s' "$icon_on" "$icon_off" "$percent"
fi
