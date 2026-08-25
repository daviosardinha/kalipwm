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
    # Do not pass --path here. In Flameshot GUI mode, --path becomes a final
    # action and can break/replace the normal Ctrl+C clipboard workflow. The
    # interactive GUI should behave like classic Flameshot: Ctrl+C copies the
    # selection to the clipboard, Ctrl+S saves only when the user asks.
    run_flameshot flameshot gui
    ;;
  full)
    # Shift+Print is intentionally the explicit save-to-disk action.
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
