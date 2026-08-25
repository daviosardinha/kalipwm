#!/usr/bin/env bash
set -u

SCREENSHOT_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

command -v flameshot >/dev/null 2>&1 || {
  command -v notify-send >/dev/null 2>&1 && notify-send "KaliPWM" "Flameshot is not installed."
  exit 127
}

ensure_daemon() {
  if ! pgrep -u "$UID" -x flameshot >/dev/null 2>&1; then
    flameshot >/dev/null 2>&1 &
    # Give Flameshot a moment to register its DBus service before asking it
    # to open a capture UI from sxhkd.
    sleep 0.35
  fi
}

run_flameshot() {
  local rc
  ensure_daemon
  "$@"
  rc=$?

  # Flameshot returns 2 when the user deliberately cancels a capture.
  (( rc == 0 || rc == 2 )) && return 0

  command -v notify-send >/dev/null 2>&1 && \
    notify-send "KaliPWM screenshot failed" "Flameshot exited with status $rc."
  return "$rc"
}

case "${1:-gui}" in
  gui|select)
    run_flameshot flameshot gui --path "$SCREENSHOT_DIR"
    ;;
  full)
    run_flameshot flameshot full --path "$SCREENSHOT_DIR"
    ;;
  launcher)
    run_flameshot flameshot launcher
    ;;
  screen)
    run_flameshot flameshot screen --path "$SCREENSHOT_DIR"
    ;;
  *)
    printf 'Usage: screenshot.sh [gui|full|launcher|screen]\n' >&2
    exit 2
    ;;
esac
