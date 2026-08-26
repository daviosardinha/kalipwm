#!/usr/bin/env bash
set -u

DIR="$HOME/.config/polybar/forest"
CONFIG="$DIR/config.ini"

stop_kalipwm_bars() {
  local pid cmdline

  while read -r pid; do
    [[ -n "$pid" ]] || continue
    cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
    [[ "$cmdline" == *"$CONFIG"* ]] || continue
    kill -TERM "$pid" 2>/dev/null || true
  done < <(pgrep -u "$UID" -x polybar 2>/dev/null || true)

  # Wait briefly only for KaliPWM-owned bars. Never block on or terminate an
  # unrelated Polybar instance the user may run for another session/profile.
  for _ in {1..50}; do
    local found=false
    while read -r pid; do
      [[ -n "$pid" ]] || continue
      cmdline="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
      if [[ "$cmdline" == *"$CONFIG"* ]]; then
        found=true
        break
      fi
    done < <(pgrep -u "$UID" -x polybar 2>/dev/null || true)
    [[ "$found" == false ]] && return 0
    sleep 0.1
  done
}

stop_kalipwm_bars

mapfile -t monitors < <(
  if command -v polybar >/dev/null 2>&1; then
    polybar --list-monitors 2>/dev/null | cut -d: -f1
  elif command -v xrandr >/dev/null 2>&1; then
    xrandr --query 2>/dev/null | awk '$2=="connected" {print $1}'
  fi
)

if ((${#monitors[@]} == 0)); then
  polybar -q main -c "$CONFIG" &
else
  for monitor in "${monitors[@]}"; do
    MONITOR="$monitor" polybar -q main -c "$CONFIG" &
  done
fi
