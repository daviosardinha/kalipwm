#!/usr/bin/env bash

for path in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do
    [ -d "$path" ] || continue
    if [ -r "$path/online" ]; then
        online=$(cat "$path/online" 2>/dev/null)
        if [ "$online" = "1" ]; then
            printf 'AC 100%%'
        else
            printf 'AC OFF'
        fi
        exit 0
    fi
done

printf 'AC N/A'
