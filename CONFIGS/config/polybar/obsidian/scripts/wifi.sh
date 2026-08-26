#!/usr/bin/env bash

iface=""
for path in /sys/class/net/*; do
    [ -d "$path/wireless" ] || continue
    iface="${path##*/}"
    break
done

if [ -z "$iface" ]; then
    printf 'WLAN OFF'
    exit 0
fi

state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || printf 'down')
ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)

if [ "$state" = "up" ] && [ -n "$ip" ]; then
    printf 'WLAN %s %s' "$iface" "$ip"
else
    printf 'WLAN %s OFF' "$iface"
fi
