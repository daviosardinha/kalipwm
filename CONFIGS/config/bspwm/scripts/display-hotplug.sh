#!/usr/bin/env bash
set -u

POLL_INTERVAL="${KALIPWM_DISPLAY_POLL_INTERVAL:-2}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/kalipwm"
LOG_FILE="$CACHE_DIR/display-hotplug.log"
LOCK_FILE="$CACHE_DIR/display-hotplug.lock"
WALLPAPER_HELPER="$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh"
POLYBAR_LAUNCHER="$HOME/.config/polybar/obsidian-v2/launch.sh"

mkdir -p "$CACHE_DIR"

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

if [ -z "${DISPLAY:-}" ] || ! command -v xrandr >/dev/null 2>&1; then
    log "Display hot-plug watcher not started: X11 display/xrandr unavailable."
    exit 0
fi

# Keep one watcher per user session even when BSPWM is restarted.
if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    if ! flock -n 9; then
        exit 0
    fi
fi

xrandr_snapshot() {
    xrandr --query 2>/dev/null
}

topology_signature() {
    local snapshot="$1"

    printf '%s\n' "$snapshot" | awk '
        $2 == "connected" {
            state = "off"
            for (i = 3; i <= NF; i++) {
                if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
                    state = "on"
                    break
                }
            }
            printf "%s:%s;", $1, state
        }
    '
}

output_is_active() {
    local snapshot="$1"
    local output="$2"

    printf '%s\n' "$snapshot" | awk -v output="$output" '
        $1 == output && $2 == "connected" {
            for (i = 3; i <= NF; i++) {
                if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) exit 0
            }
            exit 1
        }
        END { exit 1 }
    '
}

choose_primary() {
    local snapshot="$1"
    local output

    output="$(printf '%s\n' "$snapshot" | awk '$2 == "connected" && $3 == "primary" {print $1; exit}')"
    if [ -n "$output" ]; then
        printf '%s\n' "$output"
        return 0
    fi

    output="$(printf '%s\n' "$snapshot" | awk '$2 == "connected" && $1 ~ /^(eDP|LVDS)/ {print $1; exit}')"
    if [ -n "$output" ]; then
        printf '%s\n' "$output"
        return 0
    fi

    output="$(printf '%s\n' "$snapshot" | awk '
        $2 == "connected" {
            for (i = 3; i <= NF; i++) {
                if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
                    print $1
                    exit
                }
            }
        }
    ')"
    if [ -n "$output" ]; then
        printf '%s\n' "$output"
        return 0
    fi

    printf '%s\n' "$snapshot" | awk '$2 == "connected" {print $1; exit}'
}

refresh_desktop_surfaces() {
    sleep 0.5

    if [ -x "$WALLPAPER_HELPER" ]; then
        "$WALLPAPER_HELPER" >/dev/null 2>&1 || log "Wallpaper refresh failed after display change."
    fi

    if [ -x "$POLYBAR_LAUNCHER" ]; then
        "$POLYBAR_LAUNCHER" >/dev/null 2>&1 || log "Polybar refresh failed after display change."
    fi
}

configure_connected_outputs() {
    local snapshot="$1"
    local primary reference output
    local -a connected=()
    local changed=0

    mapfile -t connected < <(printf '%s\n' "$snapshot" | awk '$2 == "connected" {print $1}')
    [ "${#connected[@]}" -gt 0 ] || return 0

    primary="$(choose_primary "$snapshot")"
    [ -n "$primary" ] || return 0

    if output_is_active "$snapshot" "$primary"; then
        # Preserve the current mode/refresh rate; only ensure the primary flag.
        xrandr --output "$primary" --primary >/dev/null 2>&1 || true
    else
        log "Activating primary output $primary with its preferred mode."
        xrandr --output "$primary" --auto --primary >/dev/null 2>&1 || {
            log "Failed to activate primary output $primary."
            return 1
        }
        changed=1
        snapshot="$(xrandr_snapshot)"
    fi

    reference="$primary"
    for output in "${connected[@]}"; do
        [ "$output" = "$primary" ] && continue

        if output_is_active "$snapshot" "$output"; then
            # Respect an already-active layout chosen by the display manager/user.
            reference="$output"
            continue
        fi

        log "Activating connected output $output to the right of $reference."
        if xrandr --output "$output" --auto --right-of "$reference" >/dev/null 2>&1; then
            changed=1
            reference="$output"
            snapshot="$(xrandr_snapshot)"
        else
            log "Failed to activate connected output $output."
        fi
    done

    # A topology change can require wallpaper/Polybar refresh even when Xorg
    # already disabled an unplugged output before this script runs.
    refresh_desktop_surfaces

    if [ "$changed" -eq 1 ]; then
        log "Display topology applied: $(topology_signature "$(xrandr_snapshot)")"
    else
        log "Display topology changed; active modes/layout were preserved."
    fi
}

previous_signature=""

while :; do
    snapshot="$(xrandr_snapshot)"
    signature="$(topology_signature "$snapshot")"

    if [ -z "$previous_signature" ]; then
        previous_signature="$signature"
        if printf '%s' "$signature" | grep -q ':off;'; then
            log "Connected inactive output detected at watcher startup: $signature"
            configure_connected_outputs "$snapshot" || true
            previous_signature="$(topology_signature "$(xrandr_snapshot)")"
        else
            log "Display hot-plug watcher started: $signature"
        fi
    elif [ "$signature" != "$previous_signature" ]; then
        log "Display topology change detected: $previous_signature -> $signature"
        configure_connected_outputs "$snapshot" || true
        previous_signature="$(topology_signature "$(xrandr_snapshot)")"
    fi

    sleep "$POLL_INTERVAL"
done
