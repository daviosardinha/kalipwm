#!/usr/bin/env bash
set -u

DIR="$HOME/.config/polybar/obsidian-v2"

killall -q polybar
while pgrep -x polybar >/dev/null; do sleep 0.2; done

polybar main -c "$DIR/config.ini" >/tmp/polybar-obsidian-v2.log 2>&1 &
disown
