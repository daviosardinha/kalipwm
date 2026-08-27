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
        log "Display hot-plug watcher not started: another process still holds the watcher lock."
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
                if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/) {
                    found = 1
                    break
                }
            }
            exit
        }
        END { exit(found ? 0 : 1) }
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

mode_rate_for_output() {
    local snapshot="$1"
    local output="$2"
    local prefer_current="$3"

    printf '%s\n' "$snapshot" | awk -v output="$output" -v prefer_current="$prefer_current" '
        $1 == output && $2 == "connected" {
            inside = 1
            next
        }
        inside && $0 ~ /^[^[:space:]]/ {
            exit
        }
        inside && $1 ~ /^[0-9]+x[0-9]+$/ {
            if (fallback == "") {
                rate = $2
                gsub(/[+*]/, "", rate)
                fallback = $1 "|" rate
            }

            if (prefer_current == "1") {
                for (i = 2; i <= NF; i++) {
                    if ($i ~ /\*/) {
                        rate = $i
                        gsub(/[+*]/, "", rate)
                        print $1 "|" rate
                        found = 1
                        exit
                    }
                }
            } else {
                for (i = 2; i <= NF; i++) {
                    if ($i ~ /\+/) {
                        rate = $i
                        gsub(/[+*]/, "", rate)
                        print $1 "|" rate
                        found = 1
                        exit
                    }
                }
            }
        }
        END {
            if (!found && fallback != "") print fallback
        }
    '
}

ensure_provider_links() {
    local providers result rc

    providers="$(xrandr --listproviders 2>/dev/null || true)"

    # Hybrid Intel/NVIDIA systems commonly expose external connectors through
    # NVIDIA-G0 while the internal panel is owned by the modesetting provider.
    # Re-linking the output sink is harmless when it is already associated and
    # is required on some sessions before an atomic multi-output modeset.
    if printf '%s\n' "$providers" | grep -q 'name:NVIDIA-G0' \
        && printf '%s\n' "$providers" | grep -q 'name:modesetting'; then
        result="$(xrandr --setprovideroutputsource NVIDIA-G0 modesetting 2>&1)"
        rc=$?
        if [ "$rc" -ne 0 ]; then
            log "Failed to link NVIDIA-G0 to modesetting (exit $rc): ${result:-no error text}"
            return "$rc"
        fi
        log "Verified NVIDIA-G0 output-sink link to modesetting."
    fi

    return 0
}

refresh_desktop_surfaces() {
    sleep 0.5

    # fd 9 owns the watcher flock. Close it explicitly in child helpers so a
    # long-lived process such as Polybar cannot inherit and retain the lock.
    if [ -x "$WALLPAPER_HELPER" ]; then
        "$WALLPAPER_HELPER" 9>&- >/dev/null 2>&1 || log "Wallpaper refresh failed after display change."
    fi

    if [ -x "$POLYBAR_LAUNCHER" ]; then
        "$POLYBAR_LAUNCHER" 9>&- >/dev/null 2>&1 || log "Polybar refresh failed after display change."
    fi
}

configure_connected_outputs() {
    local snapshot="$1"
    local primary output spec mode rate width offset result rc
    local -a connected=()
    local -a ordered=()
    local -a xrandr_args=()

    mapfile -t connected < <(printf '%s\n' "$snapshot" | awk '$2 == "connected" {print $1}')
    [ "${#connected[@]}" -gt 0 ] || return 0

    primary="$(choose_primary "$snapshot")"
    [ -n "$primary" ] || return 0

    ordered+=("$primary")
    for output in "${connected[@]}"; do
        [ "$output" = "$primary" ] || ordered+=("$output")
    done

    # Do not configure hybrid outputs one at a time. On some Reverse PRIME
    # laptops, adding only the NVIDIA-owned HDMI output after the Intel panel is
    # already active fails with "Configure crtc ... failed". Build one complete
    # RandR transaction containing every connected output instead.
    ensure_provider_links || return 1

    # Provider linking can expose a different/current mode list for NVIDIA-owned
    # outputs. Always build the atomic transaction from a fresh RandR snapshot.
    snapshot="$(xrandr_snapshot)"

    offset=0
    for output in "${ordered[@]}"; do
        if output_is_active "$snapshot" "$output"; then
            spec="$(mode_rate_for_output "$snapshot" "$output" 1)"
        else
            spec="$(mode_rate_for_output "$snapshot" "$output" 0)"
        fi

        if [ -z "$spec" ]; then
            log "Cannot determine a mode for connected output $output."
            return 1
        fi

        mode="${spec%%|*}"
        rate="${spec#*|}"
        width="${mode%%x*}"
        log "Selected display mode for $output: ${mode}${rate:+ @ $rate Hz}"

        xrandr_args+=(--output "$output" --mode "$mode")
        if [ -n "$rate" ]; then
            xrandr_args+=(--rate "$rate")
        fi
        xrandr_args+=(--pos "${offset}x0")

        if [ "$output" = "$primary" ]; then
            xrandr_args+=(--primary)
        fi

        offset=$((offset + width))
    done

    log "Applying atomic display topology: ${ordered[*]}"
    result="$(xrandr "${xrandr_args[@]}" 2>&1)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        log "Atomic xrandr topology failed (exit $rc): ${result:-no error text}"
        return "$rc"
    fi

    refresh_desktop_surfaces
    log "Display topology applied: $(topology_signature "$(xrandr_snapshot)")"
    return 0
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
