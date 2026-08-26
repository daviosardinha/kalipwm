#!/usr/bin/env bash

if command -v nvidia-smi >/dev/null 2>&1; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
    [ -n "$usage" ] && { printf '%s%%' "$usage"; exit 0; }
fi

for f in /sys/class/drm/card*/device/gpu_busy_percent; do
    [ -r "$f" ] || continue
    usage=$(cat "$f" 2>/dev/null)
    [ -n "$usage" ] && { printf '%s%%' "$usage"; exit 0; }
done

printf 'N/A'
