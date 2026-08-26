#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
FILE="$STATE_DIR/kalipwm-target-${UID}"

case "${1:-}" in
  '')
    if [[ -s "$FILE" ]]; then
      cat -- "$FILE"
    else
      printf 'No Target\n'
    fi
    ;;
  reset|clear)
    rm -f -- "$FILE"
    ;;
  *)
    printf '%s\n' "$1" > "$FILE"
    ;;
esac
