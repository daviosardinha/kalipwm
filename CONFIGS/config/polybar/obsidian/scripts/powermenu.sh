#!/usr/bin/env bash

THEME="$HOME/.config/polybar/obsidian/scripts/rofi/powermenu.rasi"
LOCK='  Lock'
LOGOUT='󰍃  Logout'
SUSPEND='󰒲  Suspend'
REBOOT='  Reboot'
SHUTDOWN='  Shutdown'

choice=$(printf '%s\n%s\n%s\n%s\n%s\n' "$LOCK" "$LOGOUT" "$SUSPEND" "$REBOOT" "$SHUTDOWN" | rofi -no-config -dmenu -i -p 'Power' -theme "$THEME") || exit 0

confirm() {
    printf 'No\nYes\n' | rofi -no-config -dmenu -i -p "$1?" -theme "$THEME" | grep -qx 'Yes'
}

case "$choice" in
    "$LOCK")
        i3lock -c 0f1117
        ;;
    "$LOGOUT")
        confirm 'Logout' && bspc quit
        ;;
    "$SUSPEND")
        confirm 'Suspend' && systemctl suspend
        ;;
    "$REBOOT")
        confirm 'Reboot' && systemctl reboot
        ;;
    "$SHUTDOWN")
        confirm 'Shutdown' && systemctl poweroff
        ;;
esac
