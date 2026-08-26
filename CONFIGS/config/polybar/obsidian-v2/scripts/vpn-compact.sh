#!/usr/bin/env bash

out=$(~/.config/polybar/obsidian/scripts/vpn.sh 2>/dev/null)
case "$out" in
    "VPN OFF") printf 'OFF' ;;
    "VPN ON "*) printf '%s' "${out#VPN ON }" ;;
    *) printf '%s' "$out" ;;
esac
