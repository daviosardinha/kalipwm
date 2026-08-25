#!/usr/bin/env bash
set -u

THEME="$HOME/.config/polybar/forest/scripts/rofi/launcher.rasi"
exec rofi -no-config -show drun -modi drun -show-icons -theme "$THEME"
