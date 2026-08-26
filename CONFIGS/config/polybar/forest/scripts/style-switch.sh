#!/usr/bin/env bash
set -u

# KaliPWM V1 has one supported visual contract: Obsidian Tactical. The upstream
# theme switcher edited only the old color keys and can leave the V1 semantic
# palette (accent/healthy/warning/critical) inconsistent, so do not mutate the
# live configuration from this legacy entry point.

SDIR="$HOME/.config/polybar/forest/scripts"
message='KaliPWM V1 uses the fixed Obsidian Tactical palette.'

if command -v rofi >/dev/null 2>&1; then
  rofi -no-config -theme "$SDIR/rofi/message.rasi" -e "$message"
else
  printf '%s\n' "$message"
fi
