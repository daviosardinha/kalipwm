#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/Wallpapers/obsidian"
WP_16_SRC="$WALL_DIR/obsidian-city-16x9.jpg"
WP_WIDE_SRC="$WALL_DIR/obsidian-city-ultrawide.jpg"
CACHE_DIR="$HOME/.cache/kalipwm"
WP_16="$CACHE_DIR/obsidian-city-16x9.png"
WP_WIDE="$CACHE_DIR/obsidian-city-ultrawide.png"

mkdir -p "$CACHE_DIR"

for wallpaper in "$WP_16_SRC" "$WP_WIDE_SRC"; do
    if [ ! -s "$wallpaper" ]; then
        echo "Obsidian wallpaper missing: $wallpaper" >&2
        exit 1
    fi
done

normalize_wallpaper() {
    local src="$1" dst="$2"

    # Imlib2/feh can reject some valid JPEG encodings. ImageMagick is already
    # part of KaliPWN, so normalize the bundled asset once to a plain RGB PNG.
    if [ ! -s "$dst" ] || [ "$src" -nt "$dst" ]; then
        rm -f "$dst"
        if command -v magick >/dev/null 2>&1; then
            magick "$src" -auto-orient -strip -colorspace sRGB "$dst"
        elif command -v convert >/dev/null 2>&1; then
            convert "$src" -auto-orient -strip -colorspace sRGB "$dst"
        else
            echo "ImageMagick is required to prepare the Obsidian wallpaper." >&2
            exit 1
        fi
    fi

    if [ ! -s "$dst" ]; then
        echo "Failed to prepare Obsidian wallpaper: $src" >&2
        exit 1
    fi
}

normalize_wallpaper "$WP_16_SRC" "$WP_16"
normalize_wallpaper "$WP_WIDE_SRC" "$WP_WIDE"

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
