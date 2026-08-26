#!/usr/bin/env bash

read_temp() {
    local f="$1" v
    [ -r "$f" ] || return 1
    v=$(cat "$f" 2>/dev/null) || return 1
    [ -n "$v" ] || return 1
    if [ "$v" -gt 1000 ] 2>/dev/null; then
        v=$((v / 1000))
    fi
    printf '%s' "$v"
}

pick_hottest() {
    local current="$1" candidate="$2"
    if [ -z "$current" ] || [ "$candidate" -gt "$current" ] 2>/dev/null; then
        printf '%s' "$candidate"
    else
        printf '%s' "$current"
    fi
}

cpu=""

# Prefer thermal zones that explicitly identify themselves as CPU/package sensors.
for zone in /sys/class/thermal/thermal_zone*; do
    [ -d "$zone" ] || continue
    type=$(cat "$zone/type" 2>/dev/null || true)
    case "$type" in
        x86_pkg_temp|cpu_thermal|cpu-thermal|soc_thermal|acpitz)
            v=$(read_temp "$zone/temp") || continue
            cpu=$(pick_hottest "$cpu" "$v")
            ;;
    esac
done

# CPU hwmon drivers are more reliable on many Intel/AMD laptops.
for hw in /sys/class/hwmon/hwmon*; do
    [ -d "$hw" ] || continue
    name=$(cat "$hw/name" 2>/dev/null || true)
    case "$name" in
        coretemp|k10temp|zenpower|cpu_thermal)
            for f in "$hw"/temp*_input; do
                [ -r "$f" ] || continue
                v=$(read_temp "$f") || continue
                cpu=$(pick_hottest "$cpu" "$v")
            done
            ;;
    esac
done

# Conservative fallback if the platform exposes no named CPU sensor.
if [ -z "$cpu" ]; then
    for zone in /sys/class/thermal/thermal_zone*; do
        [ -r "$zone/temp" ] || continue
        cpu=$(read_temp "$zone/temp") && break
    done
fi

gpu=""
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1)
fi
if [ -z "$gpu" ]; then
    for hw in /sys/class/drm/card*/device/hwmon/hwmon*; do
        [ -d "$hw" ] || continue
        for f in "$hw"/temp*_input; do
            [ -r "$f" ] || continue
            gpu=$(read_temp "$f") && break 2
        done
    done
fi

cpu=${cpu:-N/A}
gpu=${gpu:-N/A}
printf 'CPU %sC GPU %sC' "$cpu" "$gpu"
