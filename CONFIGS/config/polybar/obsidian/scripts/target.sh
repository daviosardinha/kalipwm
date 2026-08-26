#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/kalipwm"
file="$state_dir/target"
mkdir -p "$state_dir"

case "${1:-}" in
    reset)
        rm -f "$file"
        ;;
    --display)
        if [ -s "$file" ]; then
            printf 'Target %s' "$(/usr/bin/cat "$file")"
        else
            printf 'No Target'
        fi
        ;;
    "")
        if [ -s "$file" ]; then
            /usr/bin/cat "$file"
        else
            printf 'No Target'
        fi
        ;;
    *)
        printf '%s\n' "$1" > "$file"
        ;;
esac
