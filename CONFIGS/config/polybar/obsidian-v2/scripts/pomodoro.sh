#!/usr/bin/env bash

# KaliPWM Polybar focus timer.
# Persistent wall-clock timer with preset and custom durations.

PRESETS=(5 10 15 20 25 30 45 60)
DEFAULT_MINUTES=25
MAX_CUSTOM_MINUTES=720
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETION_THEME="$SCRIPT_DIR/pomodoro-complete.rasi"
STATE_DIR="${KALIPWM_POMODORO_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/kalipwm}"
STATE_FILE="$STATE_DIR/pomodoro.state"
NO_UI="${KALIPWM_POMODORO_NO_UI:-${KALIPWM_POMODORO_NO_NOTIFY:-0}}"

selected=$DEFAULT_MINUTES
status="idle"
end_epoch=0
remaining=$((DEFAULT_MINUTES * 60))
flash_until=0

is_uint() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

valid_minutes() {
    is_uint "$1" && (( 10#$1 >= 1 && 10#$1 <= MAX_CUSTOM_MINUTES ))
}

load_state() {
    local key value

    [[ -r "$STATE_FILE" ]] || return 0

    while IFS='=' read -r key value; do
        case "$key" in
            selected) valid_minutes "$value" && selected=$((10#$value)) ;;
            status) [[ "$value" == "idle" || "$value" == "running" || "$value" == "paused" ]] && status="$value" ;;
            end_epoch) is_uint "$value" && end_epoch=$((10#$value)) ;;
            remaining) is_uint "$value" && remaining=$((10#$value)) ;;
            flash_until) is_uint "$value" && flash_until=$((10#$value)) ;;
        esac
    done < "$STATE_FILE"

    valid_minutes "$selected" || selected=$DEFAULT_MINUTES

    if [[ "$status" == "idle" ]]; then
        end_epoch=0
        remaining=$((selected * 60))
    elif [[ "$status" == "paused" && "$remaining" -lt 1 ]]; then
        remaining=1
    fi
}

save_state() {
    local tmp

    mkdir -p "$STATE_DIR"
    tmp="${STATE_FILE}.$$"
    {
        printf 'selected=%d\n' "$selected"
        printf 'status=%s\n' "$status"
        printf 'end_epoch=%d\n' "$end_epoch"
        printf 'remaining=%d\n' "$remaining"
        printf 'flash_until=%d\n' "$flash_until"
    } > "$tmp"
    mv -f "$tmp" "$STATE_FILE"
}

play_completion_sound() {
    [[ "$NO_UI" == "1" ]] && return 0

    if command -v canberra-gtk-play >/dev/null 2>&1; then
        canberra-gtk-play -i complete >/dev/null 2>&1 || true
        return 0
    fi

    if command -v paplay >/dev/null 2>&1 && [[ -r /usr/share/sounds/freedesktop/stereo/complete.oga ]]; then
        paplay /usr/share/sounds/freedesktop/stereo/complete.oga >/dev/null 2>&1 || true
    fi
}

show_completion_card() {
    local finished_minutes=$1 choice

    [[ "$NO_UI" == "1" ]] && return 0

    if ! command -v rofi >/dev/null 2>&1; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a KaliPWM -u normal "Focus complete" "${finished_minutes} minute session finished." >/dev/null 2>&1 || true
        fi
        return 0
    fi

    play_completion_sound

    choice="$(
        printf '%s\n' \
            'Take a 5m break' \
            "Repeat ${finished_minutes}m" \
            'Dismiss' |
            timeout 10s rofi \
                -dmenu \
                -i \
                -no-custom \
                -p '󰔟  FOCUS COMPLETE' \
                -mesg "${finished_minutes} minute session finished. Nice work." \
                -theme "$COMPLETION_THEME" 2>/dev/null
    )" || return 0

    case "$choice" in
        'Take a 5m break')
            start_minutes 5
            ;;
        "Repeat ${finished_minutes}m")
            start_minutes "$finished_minutes"
            ;;
        *)
            return 0
            ;;
    esac
}

launch_completion_card() {
    local finished_minutes=$1

    (
        show_completion_card "$finished_minutes"
    ) >/dev/null 2>&1 &
}

process_expiry() {
    local now finished_minutes

    [[ "$status" == "running" ]] || return 0
    now=$(date +%s)

    if (( end_epoch <= now )); then
        finished_minutes=$selected
        status="idle"
        end_epoch=0
        remaining=$((selected * 60))
        flash_until=$((now + 5))
        save_state
        launch_completion_card "$finished_minutes"
    fi
}

format_remaining() {
    local seconds=$1 minutes secs

    (( seconds < 0 )) && seconds=0
    minutes=$((seconds / 60))
    secs=$((seconds % 60))
    printf '%02d:%02d' "$minutes" "$secs"
}

show_status() {
    local now left

    process_expiry
    now=$(date +%s)

    case "$status" in
        running)
            left=$((end_epoch - now))
            (( left < 0 )) && left=0
            format_remaining "$left"
            ;;
        paused)
            printf 'PAUSE '
            format_remaining "$remaining"
            ;;
        idle)
            if (( flash_until > now )); then
                printf 'DONE'
            else
                printf '%dm' "$selected"
            fi
            ;;
    esac
}

start_minutes() {
    local minutes=$1 now

    valid_minutes "$minutes" || return 1
    minutes=$((10#$minutes))
    now=$(date +%s)
    selected=$minutes
    remaining=$((minutes * 60))
    end_epoch=$((now + remaining))
    status="running"
    flash_until=0
    save_state
}

toggle_timer() {
    local now

    process_expiry
    now=$(date +%s)

    case "$status" in
        idle)
            start_minutes "$selected"
            ;;
        running)
            remaining=$((end_epoch - now))
            (( remaining < 1 )) && remaining=1
            status="paused"
            end_epoch=0
            flash_until=0
            save_state
            ;;
        paused)
            end_epoch=$((now + remaining))
            status="running"
            flash_until=0
            save_state
            ;;
    esac
}

reset_timer() {
    status="idle"
    end_epoch=0
    remaining=$((selected * 60))
    flash_until=0
    save_state
}

cycle_preset() {
    local direction=$1 preset candidate="" i

    process_expiry
    [[ "$status" == "idle" ]] || return 0

    if [[ "$direction" == "next" ]]; then
        for preset in "${PRESETS[@]}"; do
            if (( preset > selected )); then
                candidate=$preset
                break
            fi
        done
        [[ -n "$candidate" ]] || candidate=${PRESETS[0]}
    else
        for ((i=${#PRESETS[@]}-1; i>=0; i--)); do
            preset=${PRESETS[$i]}
            if (( preset < selected )); then
                candidate=$preset
                break
            fi
        done
        [[ -n "$candidate" ]] || candidate=${PRESETS[${#PRESETS[@]}-1]}
    fi

    selected=$candidate
    remaining=$((selected * 60))
    flash_until=0
    save_state
}

open_menu() {
    local choice custom minutes

    command -v rofi >/dev/null 2>&1 || return 0

    choice=$(printf '%s\n' \
        '60 minutes' \
        '45 minutes' \
        '30 minutes' \
        '25 minutes' \
        '20 minutes' \
        '15 minutes' \
        '10 minutes' \
        '5 minutes' \
        'Custom…' | rofi -dmenu -i -p 'Focus timer') || return 0

    [[ -n "$choice" ]] || return 0

    if [[ "$choice" == "Custom…" ]]; then
        custom=$(printf '%s' '' | rofi -dmenu -p "Minutes (1-${MAX_CUSTOM_MINUTES})") || return 0
        if ! valid_minutes "$custom"; then
            if command -v notify-send >/dev/null 2>&1; then
                notify-send -a KaliPWM -u low "Focus timer" "Enter a whole number from 1 to ${MAX_CUSTOM_MINUTES}." >/dev/null 2>&1 || true
            fi
            return 0
        fi
        minutes=$custom
    else
        minutes=${choice%% *}
    fi

    start_minutes "$minutes"
}

preview_completion() {
    local minutes=${1:-$selected}

    valid_minutes "$minutes" || return 1
    show_completion_card "$((10#$minutes))"
}

usage() {
    cat <<'USAGE'
Usage: pomodoro.sh [status|toggle|reset|next|prev|menu|set MINUTES|preview [MINUTES]]
USAGE
}

load_state

case "${1:-status}" in
    status) show_status ;;
    toggle) toggle_timer ;;
    reset) reset_timer ;;
    next) cycle_preset next ;;
    prev) cycle_preset prev ;;
    menu) open_menu ;;
    set)
        if [[ $# -ne 2 ]] || ! valid_minutes "$2"; then
            usage >&2
            exit 2
        fi
        start_minutes "$2"
        ;;
    preview)
        if [[ $# -gt 2 ]] || { [[ $# -eq 2 ]] && ! valid_minutes "$2"; }; then
            usage >&2
            exit 2
        fi
        preview_completion "${2:-$selected}"
        ;;
    -h|--help|help) usage ;;
    *) usage >&2; exit 2 ;;
esac
