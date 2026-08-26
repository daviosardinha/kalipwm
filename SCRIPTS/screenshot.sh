#!/usr/bin/env bash
set -Eeuo pipefail

SCREENSHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

command -v flameshot >/dev/null 2>&1 || {
  command -v notify-send >/dev/null 2>&1 && notify-send "KaliPWM" "Flameshot is not installed."
  printf 'Flameshot is not installed.\n' >&2
  exit 127
}

ensure_daemon() {
  if ! pgrep -u "$UID" -x flameshot >/dev/null 2>&1; then
    flameshot >/dev/null 2>&1 &
    sleep 0.35
  fi
}

run_flameshot() {
  local rc
  ensure_daemon
  set +e
  "$@"
  rc=$?
  set -e

  # Flameshot may return 2 when the user deliberately cancels a capture.
  (( rc == 0 || rc == 2 )) && return 0

  command -v notify-send >/dev/null 2>&1 && \
    notify-send "KaliPWM screenshot failed" "Flameshot exited with status $rc."
  return "$rc"
}

case "${1:-gui}" in
  gui|select|window)
    # Interactive selection + annotation. Ctrl+C copies to clipboard and Ctrl+S
    # saves only when explicitly requested by the operator.
    run_flameshot flameshot gui
    ;;
  full)
    # Explicit full-desktop save action.
    run_flameshot flameshot full --path "$SCREENSHOT_DIR"
    ;;
  launcher)
    run_flameshot flameshot launcher
    ;;
  screen)
    run_flameshot flameshot screen --path "$SCREENSHOT_DIR"
    ;;
  *)
    printf 'Usage: screenshot.sh [gui|select|full|launcher|screen]\n' >&2
    exit 2
    ;;
esac
