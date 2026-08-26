#!/usr/bin/env bash

file=/tmp/target

case "${1:-}" in
    reset)
        rm -f "$file"
        exit 0
        ;;
    "")
        if [ -s "$file" ]; then
            cat "$file"
        else
            printf 'No Target'
        fi
        ;;
    *)
        printf '%s\n' "$1" > "$file"
        ;;
esac
