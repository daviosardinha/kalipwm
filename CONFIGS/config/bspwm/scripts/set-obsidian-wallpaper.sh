#!/usr/bin/env bash
set -euo pipefail

WALL_DIR="$HOME/Wallpapers/obsidian"
CACHE_DIR="$HOME/.cache/kalipwm"

CITY_16="$WALL_DIR/obsidian-city-16x9.jpg"
CITY_WIDE="$WALL_DIR/obsidian-city-ultrawide.jpg"
MONOLITH_STANDARD="$WALL_DIR/obsidian-nomad-monolith-standard.png"
MONOLITH_16="$WALL_DIR/obsidian-nomad-monolith-16x9.png"
EMBLEM_STANDARD="$WALL_DIR/obsidian-nomad-emblem-standard.png"
EMBLEM_16="$WALL_DIR/obsidian-nomad-emblem-16x9.png"

mkdir -p "$CACHE_DIR"

list_wallpapers() {
    cat <<'EOF'
auto
city-16x9
city-ultrawide
nomad-monolith
nomad-monolith-16x9
nomad-emblem
nomad-emblem-16x9
EOF
}

require_wallpaper() {
    local wallpaper="$1"
    if [ ! -s "$wallpaper" ]; then
        echo "Obsidian wallpaper missing: $wallpaper" >&2
        exit 1
    fi
}

apply_one() {
    local wallpaper="$1"
    require_wallpaper "$wallpaper"
    printf '%s\n' "$wallpaper" > "$CACHE_DIR/current-wallpaper"
    exec feh --bg-fill "$wallpaper"
}

city_wallpaper_for_geometry() {
    local width="$1" height="$2" ratio
    ratio=$(( width * 100 / height ))

    if [ "$ratio" -ge 200 ]; then
        printf '%s\n' "$CITY_WIDE"
    else
        printf '%s\n' "$CITY_16"
    fi
}

apply_auto() {
    local geometry width height wallpaper
    local -a wallpapers=()

    require_wallpaper "$CITY_16"
    require_wallpaper "$CITY_WIDE"

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

        wallpaper="$(city_wallpaper_for_geometry "$width" "$height")"
        wallpapers+=("$wallpaper")
    done < <(xrandr --listmonitors 2>/dev/null | awk 'NR > 1 {print $3}')

    if [ "${#wallpapers[@]}" -eq 0 ]; then
        wallpapers=("$CITY_16")
    fi

    printf '%s\n' "${wallpapers[@]}" > "$CACHE_DIR/current-wallpaper"
    exec feh --bg-fill "${wallpapers[@]}"
}

choice="${1:-auto}"

case "$choice" in
    auto|city)
        apply_auto
        ;;
    city-16x9|16|16:9|standard)
        apply_one "$CITY_16"
        ;;
    city-ultrawide|wide|ultrawide|21:9|32:9)
        apply_one "$CITY_WIDE"
        ;;
    nomad-monolith|nomad-monolith-standard)
        apply_one "$MONOLITH_STANDARD"
        ;;
    nomad-monolith-16x9)
        apply_one "$MONOLITH_16"
        ;;
    nomad-emblem|nomad-emblem-standard)
        apply_one "$EMBLEM_STANDARD"
        ;;
    nomad-emblem-16x9)
        apply_one "$EMBLEM_16"
        ;;
    list|--list)
        list_wallpapers
        ;;
    *)
        echo "Unknown wallpaper: $choice" >&2
        echo "Available wallpapers:" >&2
        list_wallpapers >&2
        exit 1
        ;;
esac
