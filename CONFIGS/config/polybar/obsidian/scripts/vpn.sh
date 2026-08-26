#!/usr/bin/env bash

iface=""
for dev in $(ls /sys/class/net 2>/dev/null); do
    case "$dev" in
        tun*|tap*|wg*|tailscale*|ppp*)
            state=$(cat "/sys/class/net/$dev/operstate" 2>/dev/null || printf 'down')
            [ "$state" = "up" ] || continue
            iface="$dev"
            break
            ;;
    esac
done

if [ -z "$iface" ]; then
    printf 'VPN OFF'
    exit 0
fi

ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
name=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 ~ /vpn|wireguard/ {print $1; exit}')
[ -n "$name" ] || name="$iface"

if [ -n "$ip" ]; then
    printf 'VPN ON %s %s' "$name" "$ip"
else
    printf 'VPN ON %s' "$name"
fi
