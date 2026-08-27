#!/usr/bin/env bash
set -euo pipefail

SCREENSHOT_DIR="$HOME/screenshots"
mkdir -p "$SCREENSHOT_DIR"

if ! command -v flameshot >/dev/null 2>&1; then
    notify-send "Flameshot is not installed." 2>/dev/null || true
    exit 127
fi

run_active_monitor_editor() {
    # Flameshot 14 changed multi-monitor GUI capture to show a monitor picker.
    # On BSPWM/X11 that picker is known to interact badly with tiling WMs.
    # The v14 screen subcommand is the supported way to bypass the picker and
    # open the editor directly on the screen containing the mouse pointer.
    if flameshot screen --help 2>&1 | grep -q -- '--edit'; then
        exec flameshot screen --edit
    fi

    # Compatibility fallback for older Flameshot releases.
    exec flameshot gui
}

case "${1:-select}" in
    select|gui)
        # Keep GUI mode clean: do not pass final-action flags here.
        # This preserves Flameshot's native interactive shortcuts such as
        # Ctrl+C (copy), Ctrl+S (save), Ctrl+Z (undo), and annotation tools.
        exec flameshot gui
        ;;
    monitor|focused|focused-monitor|active-monitor)
        run_active_monitor_editor
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
