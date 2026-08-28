#!/usr/bin/env bash

name=""
iface=""

# Prefer NetworkManager because WireGuard interfaces may have arbitrary names
# (for example: ronin66 rather than wg0).
if command -v nmcli >/dev/null 2>&1; then
    while IFS=: read -r con_name con_type con_dev; do
        case "$con_type" in
            vpn|wireguard)
                [ -n "$con_dev" ] || continue
                name="$con_name"
                iface="$con_dev"
                break
                ;;
        esac
    done < <(nmcli -t -f NAME,TYPE,DEVICE connection show --active 2>/dev/null)
fi

# WireGuard not managed by NetworkManager.
if [ -z "$iface" ] && command -v wg >/dev/null 2>&1; then
    iface=$(wg show interfaces 2>/dev/null | awk '{print $1}')
    [ -n "$iface" ] && name="$iface"
fi

# Generic tunnel fallback.
if [ -z "$iface" ]; then
    for path in /sys/class/net/*; do
        [ -e "$path" ] || continue
        dev="${path##*/}"
        case "$dev" in
            tun*|tap*|wg*|tailscale*|ppp*)
                state=$(cat "$path/operstate" 2>/dev/null || printf 'down')
                [ "$state" = "up" ] || continue
                iface="$dev"
                name="$dev"
                break
                ;;
        esac
    done
fi

if [ -z "$iface" ]; then
    printf 'VPN OFF'
    exit 0
fi

ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
[ -n "$name" ] || name="$iface"

if [ -n "$ip" ]; then
    printf 'VPN ON %s %s' "$name" "$ip"
else
    printf 'VPN ON %s' "$name"
fi
