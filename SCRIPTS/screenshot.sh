#!/usr/bin/env bash
set -euo pipefail

SCREENSHOT_DIR="$HOME/screenshots"
mkdir -p "$SCREENSHOT_DIR"

if ! command -v flameshot >/dev/null 2>&1; then
    notify-send "Flameshot is not installed." 2>/dev/null || true
    exit 127
fi

case "${1:-select}" in
    select|gui)
        # Keep GUI mode clean: do not pass final-action flags here.
        # This preserves Flameshot's native interactive shortcuts such as
        # Ctrl+C (copy), Ctrl+S (save), Ctrl+Z (undo), and the annotation tools.
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
        echo "Usage: screenshot [select|full|screen|window]" >&2
        exit 2
        ;;
esac
