#!/usr/bin/env bash

iface=""
for path in /sys/class/net/*; do
    dev="${path##*/}"
    [ "$dev" = "lo" ] && continue
    [ -d "$path/wireless" ] && continue
    case "$dev" in
        tun*|tap*|wg*|tailscale*|docker*|br-*|virbr*|veth*) continue ;;
    esac
    [ -e "$path/device" ] || continue
    iface="$dev"
    [ "$(cat "$path/operstate" 2>/dev/null)" = "up" ] && break
done

if [ -z "$iface" ]; then
    printf 'LAN OFF'
    exit 0
fi

ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
state=$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || printf 'down')

if [ "$state" = "up" ] && [ -n "$ip" ]; then
    printf 'LAN %s %s' "$iface" "$ip"
else
    printf 'LAN %s OFF' "$iface"
fi
