#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/Wallpapers/obsidian"
WP_16="$WALL_DIR/obsidian-city-16x9.webp"
WP_WIDE="$WALL_DIR/obsidian-city-ultrawide.webp"
CACHE_DIR="$HOME/.cache/kalipwm"

mkdir -p "$CACHE_DIR"

for wallpaper in "$WP_16" "$WP_WIDE"; do
    if [ ! -s "$wallpaper" ]; then
        echo "Obsidian wallpaper missing: $wallpaper" >&2
        exit 1
    fi
done

wallpaper_for_geometry() {
    local width="$1" height="$2" ratio
    ratio=$(( width * 100 / height ))

    if [ "$ratio" -ge 200 ]; then
        printf '%s\n' "$WP_WIDE"
    else
        printf '%s\n' "$WP_16"
    fi
}

apply_auto() {
    local geometry width height
    local -a wallpapers=()

    while read -r geometry; do
        [ -n "$geometry" ] || continue

        if [[ "$geometry" =~ ^([0-9]+)/[0-9]+x([0-9]+)/[0-9]+\+ ]]; then
            width="${BASH_REMATCH[1]}"
            height="${BASH_REMATCH[2]}"
        elif [[ "$geometry" =~ ^([0-9]+)x([0-9]+)\+ ]]; then
            width="${BASH_REMATCH[1]}"
            height="${BASH_REMATCH[2]}"
        else
            continue
        fi

        wallpapers+=("$(wallpaper_for_geometry "$width" "$height")")
    done < <(xrandr --listmonitors 2>/dev/null | awk 'NR > 1 {print $3}')

    if [ "${#wallpapers[@]}" -eq 0 ]; then
        wallpapers=("$WP_16")
    fi

    printf '%s\n' "${wallpapers[@]}" > "$CACHE_DIR/current-wallpaper"
    exec feh --bg-fill "${wallpapers[@]}"
}

case "${1:-auto}" in
    auto)
        apply_auto
        ;;
    16|16:9|standard)
        printf '%s\n' "$WP_16" > "$CACHE_DIR/current-wallpaper"
        exec feh --bg-fill "$WP_16"
        ;;
    wide|ultrawide|21:9|32:9)
        printf '%s\n' "$WP_WIDE" > "$CACHE_DIR/current-wallpaper"
        exec feh --bg-fill "$WP_WIDE"
        ;;
    *)
        echo "Usage: $0 [auto|16:9|ultrawide]" >&2
        exit 1
        ;;
esac
