#!/usr/bin/env bash

state=/tmp/obsidian-v2-cpu.stat
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
idle_all=$((idle + iowait))
non_idle=$((user + nice + system + irq + softirq + steal))
total=$((idle_all + non_idle))
usage=0

if [ -r "$state" ]; then
    read -r prev_total prev_idle < "$state"
    total_delta=$((total - prev_total))
    idle_delta=$((idle_all - prev_idle))
    if [ "$total_delta" -gt 0 ]; then
        usage=$((100 * (total_delta - idle_delta) / total_delta))
    fi
fi
printf '%s %s\n' "$total" "$idle_all" > "$state"

temp=$(~/.config/polybar/obsidian/scripts/thermal.sh 2>/dev/null | sed -n 's/.*CPU \([^C ]*\)C.*/\1/p')
if [ -n "$temp" ] && [ "$temp" != "N/A" ]; then
    printf '%s%% %s°' "$usage" "$temp"
else
    printf '%s%%' "$usage"
fi
