#!/usr/bin/env bash
set -u

have() {
    command -v "$1" >/dev/null 2>&1
}

case "${1:-}" in
    volume-up)
        if have wpctl; then
            exec wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        elif have pactl; then
            exec pactl set-sink-volume @DEFAULT_SINK@ +5%
        fi
        ;;
    volume-down)
        if have wpctl; then
            exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        elif have pactl; then
            exec pactl set-sink-volume @DEFAULT_SINK@ -5%
        fi
        ;;
    volume-mute)
        if have wpctl; then
            exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        elif have pactl; then
            exec pactl set-sink-mute @DEFAULT_SINK@ toggle
        fi
        ;;
    brightness-up)
        if have brightnessctl; then
            exec brightnessctl -q set +10%
        elif have xbacklight; then
            exec xbacklight -inc 10
        fi
        ;;
    brightness-down)
        if have brightnessctl; then
            exec brightnessctl -q set 10%-
        elif have xbacklight; then
            exec xbacklight -dec 10
        fi
        ;;
    *)
        printf 'Usage: %s {volume-up|volume-down|volume-mute|brightness-up|brightness-down}\n' "${0##*/}" >&2
        exit 2
        ;;
esac

exit 1
