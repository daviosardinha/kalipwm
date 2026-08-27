#!/usr/bin/env bash
set -euo pipefail

SCREENSHOT_DIR="$HOME/screenshots"
mkdir -p "$SCREENSHOT_DIR"

if ! command -v flameshot >/dev/null 2>&1; then
    notify-send "Flameshot is not installed." 2>/dev/null || true
    exit 127
fi

focused_monitor_region() {
    local monitor raw_geometry region

    command -v bspc >/dev/null 2>&1 || return 1
    command -v xrandr >/dev/null 2>&1 || return 1

    monitor="$(bspc query -M -m focused --names 2>/dev/null || true)"
    [ -n "$monitor" ] || return 1

    raw_geometry="$(xrandr --listactivemonitors 2>/dev/null | awk -v monitor="$monitor" '$NF == monitor {print $3; exit}')"
    [ -n "$raw_geometry" ] || return 1

    region="$(printf '%s\n' "$raw_geometry" | sed -E 's#^([0-9]+)/[0-9]+x([0-9]+)/[0-9]+\+([0-9]+)\+([0-9]+)$#\1x\2+\3+\4#')"

    if [[ "$region" =~ ^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$ ]]; then
        printf '%s\n' "$region"
        return 0
    fi

    return 1
}

case "${1:-select}" in
    select|gui)
        # Keep GUI mode clean: do not pass final-action flags here.
        # This preserves Flameshot's native interactive shortcuts such as
        # Ctrl+C (copy), Ctrl+S (save), Ctrl+Z (undo), and the annotation tools.
        exec flameshot gui
        ;;
    monitor|focused|focused-monitor)
        # On mixed-resolution multi-monitor layouts, Qt can render Flameshot's
        # global capture canvas incorrectly. Restrict GUI capture to the BSPWM
        # focused monitor when its RandR geometry can be resolved.
        region="$(focused_monitor_region || true)"
        if [ -n "$region" ]; then
            exec flameshot gui --region "$region"
        fi
        exec flameshot gui
        ;;
    full)
        exec flameshot full --path "$SCREENSHOT_DIR"
        ;;
    screen)
        exec flameshot screen --path "$SCREENSHOT_DIR"
        ;;
    window)
        # Flameshot has no native active-window CLI mode; use GUI selection.
        exec flameshot gui
        ;;
    *)
        echo "Usage: screenshot [select|monitor|full|screen|window]" >&2
        exit 2
        ;;
esac
