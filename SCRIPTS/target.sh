#!/usr/bin/env bash
set -u

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
FILE="$STATE_DIR/kalipwm-target-${UID}"

case "${1:-}" in
  '')
    if [[ -s "$FILE" ]]; then
      cat "$FILE"
    else
      printf 'NO TARGET\n'
    fi
    ;;
  reset|clear)
    rm -f -- "$FILE"
    ;;
  *)
    printf '%s\n' "$1" > "$FILE"
    ;;
esac
