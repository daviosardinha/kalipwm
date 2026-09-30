#!/usr/bin/env bash
set -Eeuo pipefail

have() {
    command -v "$1" >/dev/null 2>&1
}

require_x11() {
    if [ -z "${DISPLAY:-}" ]; then
        printf 'KaliPWM display helper requires an active X11 DISPLAY.\n' >&2
        return 1
    fi
    if ! have xrandr; then
        printf 'KaliPWM display helper requires xrandr.\n' >&2
        return 1
    fi
}

connected_outputs() {
    xrandr --query 2>/dev/null |
        awk '$2 == "connected" {print $1}'
}

active_outputs() {
    xrandr --query 2>/dev/null |
        awk '
            $2 == "connected" {
                for (i = 3; i <= NF; i++) {
                    if ($i ~ /^[0-9]+x[0-9]+[+-][0-9]+[+-][0-9]+$/) {
                        print $1
                        break
                    }
                }
            }
        '
}

primary_output() {
    xrandr --query 2>/dev/null |
        awk '
            $2 == "connected" {
                for (i = 3; i <= NF; i++) {
                    if ($i == "primary") {
                        print $1
                        exit
                    }
                }
            }
        '
}

is_internal_output() {
    case "$1" in
        eDP*|EDP*|LVDS*|DSI*) return 0 ;;
        *) return 1 ;;
    esac
}

contains_output() {
    local needle="$1"
    shift
    local item

    for item in "$@"; do
        [ "$item" = "$needle" ] && return 0
    done
    return 1
}

choose_anchor() {
    local primary output
    local -a active=("$@")

    primary="$(primary_output)"
    if [ -n "$primary" ] && contains_output "$primary" "${active[@]}"; then
        printf '%s\n' "$primary"
        return 0
    fi

    for output in "${active[@]}"; do
        if is_internal_output "$output"; then
            printf '%s\n' "$output"
            return 0
        fi
    done

    if [ "${#active[@]}" -gt 0 ]; then
        printf '%s\n' "${active[0]}"
        return 0
    fi

    return 1
}

auto_enable_connected_outputs() {
    local anchor output
    local -a connected active

    require_x11 || return 1

    mapfile -t connected < <(connected_outputs)
    mapfile -t active < <(active_outputs)

    if [ "${#connected[@]}" -eq 0 ]; then
        printf 'No connected XRandR outputs were detected.\n' >&2
        return 1
    fi

    if [ "${#active[@]}" -eq 0 ]; then
        anchor=""
        for output in "${connected[@]}"; do
            if is_internal_output "$output"; then
                anchor="$output"
                break
            fi
        done
        [ -n "$anchor" ] || anchor="${connected[0]}"

        xrandr --output "$anchor" --auto --primary
        active=("$anchor")
    else
        anchor="$(choose_anchor "${active[@]}")"
        if [ -z "$(primary_output)" ]; then
            xrandr --output "$anchor" --primary
        fi
    fi

    for output in "${connected[@]}"; do
        contains_output "$output" "${active[@]}" && continue

        # Preserve deliberate external-only layouts. Laptop/internal panels that
        # are already disabled stay disabled when another output is active.
        if is_internal_output "$output" && [ "${#active[@]}" -gt 0 ]; then
            continue
        fi

        # Newly connected external outputs are made usable without relying on an
        # XFCE/GNOME display daemon. Chain multiple new outputs from left to right.
        xrandr --output "$output" --auto --right-of "$anchor"
        active+=("$output")
        anchor="$output"
    done
}

configure_bspwm_workspaces() {
    local monitor_count usable_count i start end count
    local -a monitors desktops slice

    if ! have bspc; then
        printf 'bspc is unavailable; cannot configure BSPWM workspaces.\n' >&2
        return 1
    fi

    mapfile -t monitors < <(bspc query -M --names 2>/dev/null)
    desktops=(I II III IV V VI VII VIII IX X)

    monitor_count="${#monitors[@]}"
    if [ "$monitor_count" -eq 0 ]; then
        printf 'BSPWM reported no monitors.\n' >&2
        return 1
    fi

    usable_count="$monitor_count"
    [ "$usable_count" -le "${#desktops[@]}" ] || usable_count="${#desktops[@]}"

    for ((i = 0; i < usable_count; i++)); do
        start=$(( i * ${#desktops[@]} / usable_count ))
        end=$(( (i + 1) * ${#desktops[@]} / usable_count - 1 ))
        count=$(( end - start + 1 ))
        slice=("${desktops[@]:start:count}")
        bspc monitor "${monitors[$i]}" -d "${slice[@]}"
    done
}

topology_signature() {
    require_x11 || return 1

    xrandr --query 2>/dev/null |
        awk '
            $2 == "connected" {
                state = "inactive"
                geometry = "-"
                for (i = 3; i <= NF; i++) {
                    if ($i ~ /^[0-9]+x[0-9]+[+-][0-9]+[+-][0-9]+$/) {
                        state = "active"
                        geometry = $i
                        break
                    }
                }
                printf "%s:%s:%s\n", $1, state, geometry
            }
        ' |
        sort
}

watch_hotplug() {
    local interval settle runtime_dir lock_file previous current

    require_x11 || return 1

    if ! have flock; then
        printf 'KaliPWM display watcher requires flock.\n' >&2
        return 1
    fi

    interval="${KALIPWM_DISPLAY_WATCH_INTERVAL:-2}"
    settle="${KALIPWM_DISPLAY_SETTLE_DELAY:-1}"
    runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
    lock_file="$runtime_dir/kalipwm-display-watch-${UID}.lock"

    # BSPWM can re-run bspwmrc during a managed display refresh. Keep exactly
    # one watcher alive across those reloads instead of stacking poll loops.
    exec 9>"$lock_file"
    if ! flock -n 9; then
        return 0
    fi

    previous="$(topology_signature)"

    while sleep "$interval"; do
        current="$(topology_signature)"
        [ "$current" = "$previous" ] && continue

        printf '[%s] XRandR topology change detected.\n' "$(date '+%Y-%m-%d %H:%M:%S')" >&2

        # Hybrid-GPU/PRIME connectors can briefly disappear or report stale
        # state while the provider settles. Debounce once, then let the next
        # poll handle any later provider transition.
        sleep "$settle"
        auto_enable_connected_outputs || true
        sleep 0.4

        current="$(topology_signature)"

        # Reload BSPWM only after a real XRandR topology transition. This makes
        # BSPWM drop stale monitors after disconnects and rebuilds workspaces,
        # wallpaper and per-monitor Polybar instances after connects.
        if have bspc; then
            bspc wm -r || true
        fi

        previous="$current"
    done
}

status() {
    require_x11 || return 1

    printf '%s\n' 'Connected outputs:'
    xrandr --query 2>/dev/null |
        awk '
            $2 == "connected" {
                state = "inactive"
                geometry = "-"
                primary = ""
                for (i = 3; i <= NF; i++) {
                    if ($i == "primary") {
                        primary = " primary"
                    }
                    if ($i ~ /^[0-9]+x[0-9]+[+-][0-9]+[+-][0-9]+$/) {
                        state = "active"
                        geometry = $i
                    }
                }
                printf "  %-14s %-8s %-24s%s\n", $1, state, geometry, primary
            }
        '
}

diagnose() {
    require_x11 || return 1

    status
    printf '\n%s\n' 'XRandR providers:'
    xrandr --listproviders 2>&1 || true

    if have bspc; then
        printf '\n%s\n' 'BSPWM monitors:'
        bspc query -M --names 2>&1 || true

        printf '\n%s\n' 'BSPWM desktops:'
        bspc query -D --names 2>&1 || true
    fi
}

usage() {
    cat <<'EOF'
Usage:
  kalipwm-display.sh auto
  kalipwm-display.sh workspaces
  kalipwm-display.sh watch
  kalipwm-display.sh status
  kalipwm-display.sh diagnose

Commands:
  auto        Activate connected external outputs that X left inactive.
              Existing active layouts are preserved.
  workspaces  Distribute KaliPWM workspaces I-X across active BSPWM monitors.
  watch       Watch the XRandR topology and reconcile live connect/disconnect
              events, including delayed hybrid-GPU provider transitions.
  status      Show connected outputs and whether each one is active.
  diagnose    Show XRandR outputs/providers plus BSPWM monitor/desktop state.
EOF
}

case "${1:-status}" in
    auto)
        auto_enable_connected_outputs
        ;;
    workspaces)
        configure_bspwm_workspaces
        ;;
    watch)
        watch_hotplug
        ;;
    status)
        status
        ;;
    diagnose)
        diagnose
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        printf 'Unknown display helper command: %s\n\n' "$1" >&2
        usage >&2
        exit 2
        ;;
esac
