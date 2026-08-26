#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/Wallpapers/obsidian"
WP_16="$WALL_DIR/obsidian-city-16x9.jpg"
WP_WIDE="$WALL_DIR/obsidian-city-ultrawide.jpg"

pick_wallpaper() {
    local output mode width height ratio

    output=$(xrandr --query | awk '/ connected primary / {print $1; exit} / connected / {print $1; exit}')
    mode=$(xrandr --query | awk -v out="$output" '
        $1 == out && $2 == "connected" {
            for (i=1; i<=NF; i++) {
                if ($i ~ /^[0-9]+x[0-9]+\+/) {
                    split($i, a, "+")
                    print a[1]
                    exit
                }
            }
        }')

    if [ -z "${mode:-}" ]; then
        printf '%s\n' "$WP_16"
        return
    fi

    width=${mode%x*}
    height=${mode#*x}
    ratio=$(( width * 100 / height ))

    if [ "$ratio" -ge 200 ]; then
        printf '%s\n' "$WP_WIDE"
    else
        printf '%s\n' "$WP_16"
    fi
}

case "${1:-auto}" in
    auto) wallpaper=$(pick_wallpaper) ;;
    16|16:9|standard) wallpaper="$WP_16" ;;
    wide|ultrawide|21:9) wallpaper="$WP_WIDE" ;;
    *)
        echo "Usage: $0 [auto|16:9|ultrawide]" >&2
        exit 1
        ;;
esac

if [ ! -f "$wallpaper" ]; then
    echo "Obsidian wallpaper missing: $wallpaper" >&2
    exit 1
fi

mkdir -p "$HOME/.cache/kalipwm"
printf '%s\n' "$wallpaper" > "$HOME/.cache/kalipwm/current-wallpaper"
exec feh --bg-fill "$wallpaper"
