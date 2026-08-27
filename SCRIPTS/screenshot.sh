#!/usr/bin/env bash
set -euo pipefail

SCREENSHOT_DIR="$HOME/screenshots"
mkdir -p "$SCREENSHOT_DIR"

if ! command -v flameshot >/dev/null 2>&1; then
    notify-send "Flameshot is not installed." 2>/dev/null || true
    exit 127
fi

case "${1:-full}" in
    select|gui)
        exec flameshot gui --path "$SCREENSHOT_DIR"
        ;;
    full)
        exec flameshot full --path "$SCREENSHOT_DIR"
        ;;
    screen)
        exec flameshot screen --path "$SCREENSHOT_DIR"
        ;;
    window)
        # Flameshot has no native active-window CLI mode; use GUI selection instead.
        exec flameshot gui --path "$SCREENSHOT_DIR"
        ;;
    *)
        echo "Usage: screenshot [select|full|screen|window]" >&2
        exit 2
        ;;
esac
