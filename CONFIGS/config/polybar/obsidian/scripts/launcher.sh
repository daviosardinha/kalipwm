#!/usr/bin/env bash

THEME="$HOME/.config/polybar/obsidian/scripts/rofi/launcher.rasi"
exec rofi -no-config -show drun -modi drun -theme "$THEME"
