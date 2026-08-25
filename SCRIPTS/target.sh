#!/usr/bin/env bash
set -u

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}"
FILE="$STATE_DIR/kalipwm-target-${UID}"

case "${1:-}" in
  '')
    if [[ -s "$FILE" ]]; then
      value="$(cat "$FILE")"
      printf '%%{F#C95B6A}TARGET %s%%{F-}\n' "$value"
    else
      printf '%%{F#9298A6}NO TARGET%%{F-}\n'
    fi
    ;;
  reset|clear)
    rm -f -- "$FILE"
    ;;
  *)
    printf '%s\n' "$1" > "$FILE"
    ;;
esac
