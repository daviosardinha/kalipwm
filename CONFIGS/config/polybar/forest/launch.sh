#!/usr/bin/env bash
set -u

DIR="$HOME/.config/polybar/forest"

pkill -x polybar 2>/dev/null || true
while pgrep -u "$UID" -x polybar >/dev/null 2>&1; do sleep 0.1; done

mapfile -t monitors < <(
  if command -v polybar >/dev/null 2>&1; then
    polybar --list-monitors 2>/dev/null | cut -d: -f1
  elif command -v xrandr >/dev/null 2>&1; then
    xrandr --query 2>/dev/null | awk '$2=="connected" {print $1}'
  fi
)

if ((${#monitors[@]} == 0)); then
  polybar -q main -c "$DIR/config.ini" &
else
  for monitor in "${monitors[@]}"; do
    MONITOR="$monitor" polybar -q main -c "$DIR/config.ini" &
  done
fi
