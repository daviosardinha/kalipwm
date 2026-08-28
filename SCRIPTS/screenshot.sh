#!/usr/bin/env bash
set -euo pipefail

SCREENSHOT_DIR="$HOME/screenshots"
FLAMESHOT_CONFIG="$HOME/.config/flameshot/flameshot.ini"
mkdir -p "$SCREENSHOT_DIR"

ensure_flameshot_x11_backend() {
    local tmp

    # Flameshot 14+ prefers xdg-desktop-portal on Linux. Minimal X11 window
    # managers such as BSPWM may not expose the Screenshot portal, causing a
    # 30-second timeout. KaliPWM therefore keeps Flameshot on its validated
    # legacy X11 capture backend while running an X11 session.
    [ -n "${DISPLAY:-}" ] || return 0
    [ "${XDG_SESSION_TYPE:-x11}" != "wayland" ] || return 0

    mkdir -p "$(dirname "$FLAMESHOT_CONFIG")"

    if [ ! -f "$FLAMESHOT_CONFIG" ]; then
        printf '[General]\nuseX11LegacyScreenshot=true\n' >"$FLAMESHOT_CONFIG"
        return 0
    fi

    if grep -Eq '^[[:space:]]*useX11LegacyScreenshot[[:space:]]*=[[:space:]]*true[[:space:]]*$' "$FLAMESHOT_CONFIG"; then
        return 0
    fi

    tmp="$(mktemp "${FLAMESHOT_CONFIG}.tmp.XXXXXX")"

    if grep -Eq '^[[:space:]]*useX11LegacyScreenshot[[:space:]]*=' "$FLAMESHOT_CONFIG"; then
        sed -E 's/^[[:space:]]*useX11LegacyScreenshot[[:space:]]*=.*/useX11LegacyScreenshot=true/' \
            "$FLAMESHOT_CONFIG" >"$tmp"
    elif grep -Fxq '[General]' "$FLAMESHOT_CONFIG"; then
        awk '
            BEGIN { inserted = 0 }
            $0 == "[General]" && !inserted {
                print
                print "useX11LegacyScreenshot=true"
                inserted = 1
                next
            }
            { print }
        ' "$FLAMESHOT_CONFIG" >"$tmp"
    else
        cat "$FLAMESHOT_CONFIG" >"$tmp"
        printf '\n[General]\nuseX11LegacyScreenshot=true\n' >>"$tmp"
    fi

    mv "$tmp" "$FLAMESHOT_CONFIG"
}

if ! command -v flameshot >/dev/null 2>&1; then
    notify-send "Flameshot is not installed." 2>/dev/null || true
    exit 127
fi

ensure_flameshot_x11_backend

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