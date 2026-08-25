#!/usr/bin/env bash
set -u

# KaliPWM V1 — Obsidian Tactical power menu

dir="${XDG_CONFIG_HOME:-$HOME/.config}/polybar/forest/scripts/rofi"
uptime_text="$(uptime -p 2>/dev/null | sed -e 's/^up //' || true)"

rofi_command=(rofi -no-config -theme "$dir/powermenu.rasi")

# Nerd Font glyphs from the same family used by the rest of KaliPWM.
shutdown="󰐥  Shutdown"
reboot="󰜉  Restart"
lock="󰌾  Lock"
suspend="󰤄  Sleep"
logout="󰗽  Logout"

confirm_exit() {
    printf 'Yes\nNo\n' | rofi -dmenu \
        -no-config \
        -i \
        -no-fixed-num-lines \
        -p "Confirm" \
        -theme "$dir/confirm.rasi"
}

message() {
    rofi -no-config -theme "$dir/message.rasi" -e "$1"
}

confirm_action() {
    [[ "$(confirm_exit)" == "Yes" ]]
}

chosen="$(printf '%s\n' "$lock" "$suspend" "$logout" "$reboot" "$shutdown" \
    | "${rofi_command[@]}" -p "UPTIME  ${uptime_text:-unknown}" -dmenu -selected-row 0)"

case "$chosen" in
    "$shutdown")
        confirm_action && systemctl poweroff
        ;;
    "$reboot")
        confirm_action && systemctl reboot
        ;;
    "$lock")
        if command -v betterlockscreen >/dev/null 2>&1; then
            betterlockscreen -l
        elif command -v i3lock >/dev/null 2>&1; then
            i3lock
        elif command -v loginctl >/dev/null 2>&1; then
            loginctl lock-session
        else
            message "No supported screen locker is available."
        fi
        ;;
    "$suspend")
        confirm_action && systemctl suspend
        ;;
    "$logout")
        if confirm_action; then
            if command -v bspc >/dev/null 2>&1; then
                bspc quit
            else
                message "BSPWM control utility is unavailable."
            fi
        fi
        ;;
    '')
        exit 0
        ;;
esac
