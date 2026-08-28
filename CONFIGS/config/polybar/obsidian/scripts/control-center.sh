#!/usr/bin/env bash
set -u

BASE="$HOME/.config/polybar/obsidian/scripts"
THEME="$BASE/rofi/control-center.rasi"
REPORT_THEME="$BASE/rofi/report.rasi"
CONFIRM_THEME="$BASE/rofi/confirm.rasi"
POWER_MENU="$BASE/powermenu.sh"
MEDIA_KEYS="$BASE/media-keys.sh"
TARGET_CMD="$(command -v target 2>/dev/null || true)"
WALLPAPER_CMD="$(command -v wallpaper 2>/dev/null || true)"
SCREENSHOT_CMD="$(command -v screenshot 2>/dev/null || true)"
BACK='󰁍  Back'

[ -n "$TARGET_CMD" ] || TARGET_CMD="$BASE/target.sh"
[ -n "$WALLPAPER_CMD" ] || WALLPAPER_CMD="$HOME/.config/bspwm/scripts/set-obsidian-wallpaper.sh"
[ -n "$SCREENSHOT_CMD" ] || SCREENSHOT_CMD="$BASE/screenshot.sh"

have() {
    command -v "$1" >/dev/null 2>&1
}

choose() {
    local prompt="$1"
    local status="$2"
    shift 2

    printf '%s\n' "$@" | rofi -no-config -dmenu -i -p "$prompt" -mesg "$status" -theme "$THEME"
}

input_value() {
    local prompt="$1"
    printf '' | rofi -no-config -dmenu -p "$prompt" -theme "$THEME"
}

confirm() {
    printf 'No\nYes\n' | rofi -no-config -dmenu -i -p "$1?" -theme "$CONFIRM_THEME" | grep -qx 'Yes'
}

notice() {
    local text="$1"
    if have notify-send; then
        notify-send -a 'KaliPWM Control Center' 'KaliPWM' "$text"
    else
        printf '%s\n' "$text" | rofi -no-config -dmenu -p 'KaliPWM' -theme "$THEME" >/dev/null
    fi
}

show_report() {
    local title="$1"
    local command="$2"
    local output rc

    output="$(bash -lc "$command" 2>&1)"
    rc=$?
    [ -n "$output" ] || output='No output.'

    printf '%s\n' "$output" |
        rofi -no-config -dmenu -i -p "$title" -mesg "Read-only report • exit $rc • Esc/Enter to close" -theme "$REPORT_THEME" >/dev/null
}

run_background() {
    local title="$1"
    local command="$2"
    local logfile="/tmp/kalipwm-control-${title//[^A-Za-z0-9]/-}.log"

    (
        if bash -lc "$command" >"$logfile" 2>&1; then
            have notify-send && notify-send -a 'KaliPWM Control Center' 'KaliPWM' "$title completed."
        else
            have notify-send && notify-send -a 'KaliPWM Control Center' 'KaliPWM' "$title failed. See $logfile"
        fi
    ) &

    notice "$title started in background."
}

kitty_path() {
    if [ -x "$HOME/.local/kitty.app/bin/kitty" ]; then
        printf '%s' "$HOME/.local/kitty.app/bin/kitty"
    elif have kitty; then
        command -v kitty
    else
        return 1
    fi
}

open_interactive_terminal() {
    local title="$1"
    local command="$2"
    local kitty

    kitty="$(kitty_path || true)"
    if [ -z "$kitty" ]; then
        notice 'Kitty is unavailable.'
        return 1
    fi

    "$kitty" --title "$title" bash -lc "$command" >/dev/null 2>&1 &
}

copy_clipboard() {
    local value="$1"

    if have xclip; then
        printf '%s' "$value" | xclip -selection clipboard
    elif have xsel; then
        printf '%s' "$value" | xsel --clipboard --input
    else
        notice 'No clipboard helper is available.'
        return 1
    fi
}

find_vpn_interface() {
    ip -o link show 2>/dev/null |
        awk -F': ' '$2 ~ /^(tun[0-9]*|tap[0-9]*|wg[0-9]*|ppp[0-9]*)$/ {print $2; exit}'
}

network_menu() {
    local choice default_if default_ip wifi_state status toggle_label network_cmd

    while true; do
        default_if="$(ip route show default 2>/dev/null | awk '/default/ {for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')"
        default_ip=""
        [ -n "$default_if" ] && default_ip="$(ip -4 -o addr show dev "$default_if" scope global 2>/dev/null | awk '{print $4; exit}')"
        status="Default: ${default_if:-none}${default_ip:+  $default_ip}"

        if have nmcli; then
            wifi_state="$(nmcli radio wifi 2>/dev/null || printf 'unknown')"
            if [ "$wifi_state" = 'enabled' ]; then
                toggle_label='󰤭  Disable Wi-Fi'
            else
                toggle_label='󰤨  Enable Wi-Fi'
            fi
            choice="$(choose 'Network' "$status" '󰈀  Network status' "$toggle_label" '󰌘  NetworkManager (nmtui)' "$BACK")" || return 0
        else
            choice="$(choose 'Network' "$status" '󰈀  Network status' "$BACK")" || return 0
        fi

        case "$choice" in
            '󰈀  Network status')
                network_cmd="printf '=== Network ===\\n'; ip -brief address; printf '\\n=== Routes ===\\n'; ip route"
                if have nmcli; then
                    network_cmd="printf '=== NetworkManager ===\\n'; nmcli general status; printf '\\n'; nmcli device status; printf '\\n=== Addresses ===\\n'; ip -brief address; printf '\\n=== Routes ===\\n'; ip route"
                fi
                show_report 'Network status' "$network_cmd"
                ;;
            '󰤭  Disable Wi-Fi')
                nmcli radio wifi off && notice 'Wi-Fi disabled.'
                ;;
            '󰤨  Enable Wi-Fi')
                nmcli radio wifi on && notice 'Wi-Fi enabled.'
                ;;
            '󰌘  NetworkManager (nmtui)')
                if have nmtui; then
                    open_interactive_terminal 'NetworkManager' 'nmtui'
                else
                    notice 'nmtui is unavailable.'
                fi
                ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

vpn_menu() {
    local choice vpn_if vpn_ip status active
    local -a entries connections

    while true; do
        vpn_if="$(find_vpn_interface)"
        vpn_ip=""
        [ -n "$vpn_if" ] && vpn_ip="$(ip -4 -o addr show dev "$vpn_if" scope global 2>/dev/null | awk '{print $4; exit}')"
        if [ -n "$vpn_if" ]; then
            status="Connected: $vpn_if${vpn_ip:+  $vpn_ip}"
        else
            status='No tunnel interface detected'
        fi

        entries=('󰦝  VPN status')
        connections=()
        if have nmcli; then
            mapfile -t connections < <(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | awk -F: '$2 == "vpn" || $2 == "wireguard" {print $1}')
            [ "${#connections[@]}" -gt 0 ] && entries+=('󰅖  Disconnect NetworkManager VPN')
            have nmtui && entries+=('󰌘  NetworkManager (nmtui)')
        fi
        entries+=("$BACK")

        choice="$(choose 'VPN' "$status" "${entries[@]}")" || return 0
        case "$choice" in
            '󰦝  VPN status')
                show_report 'VPN status' "printf '=== Tunnel interfaces ===\\n'; ip -brief address | awk '\$1 ~ /^(tun|tap|wg|ppp)/ {print}'; printf '\\n=== Active NetworkManager connections ===\\n'; if command -v nmcli >/dev/null 2>&1; then nmcli connection show --active; else printf 'nmcli unavailable\\n'; fi"
                ;;
            '󰅖  Disconnect NetworkManager VPN')
                active="$(choose 'Disconnect VPN' 'Select an active NetworkManager VPN connection' "${connections[@]}" "$BACK")" || continue
                [ "$active" = "$BACK" ] && continue
                [ -n "$active" ] || continue
                if confirm "Disconnect $active"; then
                    nmcli connection down id "$active" && notice "Disconnected $active."
                fi
                ;;
            '󰌘  NetworkManager (nmtui)')
                open_interactive_terminal 'NetworkManager' 'nmtui'
                ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

target_menu() {
    local choice current value status

    while true; do
        current="$($TARGET_CMD 2>/dev/null || printf 'No Target')"
        status="Current: $current"
        choice="$(choose 'Target' "$status" '  Set target' '󰆴  Clear target' '󰆏  Copy target' "$BACK")" || return 0

        case "$choice" in
            '  Set target')
                value="$(input_value 'Set Target')" || continue
                [ -n "$value" ] || continue
                "$TARGET_CMD" "$value" && notice "Target set: $value"
                ;;
            '󰆴  Clear target')
                if [ "$current" != 'No Target' ] && confirm 'Clear target'; then
                    "$TARGET_CMD" reset && notice 'Target cleared.'
                fi
                ;;
            '󰆏  Copy target')
                if [ "$current" = 'No Target' ]; then
                    notice 'No target is currently set.'
                elif copy_clipboard "$current"; then
                    notice "Copied target: $current"
                fi
                ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

wallpaper_menu() {
    local choice current
    local -a wallpapers entries

    while true; do
        current='auto'
        [ -s "${XDG_CACHE_HOME:-$HOME/.cache}/kalipwm/wallpaper-choice" ] && current="$(/usr/bin/cat "${XDG_CACHE_HOME:-$HOME/.cache}/kalipwm/wallpaper-choice")"
        mapfile -t wallpapers < <("$WALLPAPER_CMD" list 2>/dev/null)
        entries=("${wallpapers[@]}" "$BACK")
        choice="$(choose 'Wallpaper' "Current: $current" "${entries[@]}")" || return 0
        [ "$choice" = "$BACK" ] && return 0
        [ -n "$choice" ] || continue

        "$WALLPAPER_CMD" "$choice" >/tmp/kalipwm-wallpaper.log 2>&1 &
        notice "Wallpaper: $choice"
    done
}

screenshot_menu() {
    local choice

    while true; do
        choice="$(choose 'Screenshot' 'Flameshot workflow' '󰹑  Select region' '󰍹  Full screen' '󰩭  Screen capture' '󰖲  Window / region' '  Open screenshots folder' "$BACK")" || return 0
        case "$choice" in
            '󰹑  Select region') "$SCREENSHOT_CMD" select >/dev/null 2>&1 & exit 0 ;;
            '󰍹  Full screen') "$SCREENSHOT_CMD" full >/dev/null 2>&1 & exit 0 ;;
            '󰩭  Screen capture') "$SCREENSHOT_CMD" screen >/dev/null 2>&1 & exit 0 ;;
            '󰖲  Window / region') "$SCREENSHOT_CMD" window >/dev/null 2>&1 & exit 0 ;;
            '  Open screenshots folder')
                if have thunar; then
                    thunar "$HOME/screenshots" >/dev/null 2>&1 &
                else
                    notice 'Thunar is unavailable.'
                fi
                ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

display_menu() {
    local choice status
    local -a entries

    while true; do
        status="$(xrandr --current 2>/dev/null | awk '/ connected/{printf "%s%s ", $1, ($3 ~ /^[0-9]+x[0-9]+/) ? " " $3 : ""}' || true)"
        [ -n "$status" ] || status='Display status unavailable'

        entries=('󰍹  Display status')
        if [ -x "$MEDIA_KEYS" ] && { have brightnessctl || have xbacklight; }; then
            entries+=('󰃞  Brightness +10%' '󰃝  Brightness -10%')
        fi
        have arandr && entries+=('󰹑  Open ARandR')
        entries+=("$BACK")

        choice="$(choose 'Display' "$status" "${entries[@]}")" || return 0

        case "$choice" in
            '󰍹  Display status') show_report 'Display status' 'xrandr --current' ;;
            '󰃞  Brightness +10%') "$MEDIA_KEYS" brightness-up ;;
            '󰃝  Brightness -10%') "$MEDIA_KEYS" brightness-down ;;
            '󰹑  Open ARandR') arandr >/dev/null 2>&1 & ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

audio_menu() {
    local choice volume mute status

    while true; do
        volume='unknown'
        mute='unknown'
        if have wpctl; then
            status="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || printf 'Volume unavailable')"
            choice="$(choose 'Audio' "$status" '  Volume +5%' '  Volume -5%' '󰖁  Toggle mute' '󰓃  Open pavucontrol' "$BACK")" || return 0
        elif have pactl; then
            volume="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -n1)"
            mute="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')"
            status="Volume: ${volume:-unknown}  Mute: ${mute:-unknown}"
            choice="$(choose 'Audio' "$status" '  Volume +5%' '  Volume -5%' '󰖁  Toggle mute' '󰓃  Open pavucontrol' "$BACK")" || return 0
        else
            choice="$(choose 'Audio' 'Audio control unavailable' '󰓃  Open pavucontrol' "$BACK")" || return 0
        fi

        case "$choice" in
            '  Volume +5%') [ -x "$MEDIA_KEYS" ] && "$MEDIA_KEYS" volume-up ;;
            '  Volume -5%') [ -x "$MEDIA_KEYS" ] && "$MEDIA_KEYS" volume-down ;;
            '󰖁  Toggle mute') [ -x "$MEDIA_KEYS" ] && "$MEDIA_KEYS" volume-mute ;;
            '󰓃  Open pavucontrol')
                if have pavucontrol; then
                    pavucontrol >/dev/null 2>&1 &
                else
                    notice 'pavucontrol is unavailable.'
                fi
                ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

system_menu() {
    local choice

    while true; do
        choice="$(choose 'System' 'Safe KaliPWM management actions' '  System summary' '󰆓  Create configuration backup' '󰋚  List backups' '󰁯  Repair dry-run' "$BACK")" || return 0
        case "$choice" in
            '  System summary')
                open_interactive_terminal 'System Summary' 'clear; if command -v fastfetch >/dev/null 2>&1; then fastfetch; else uname -a; printf "\n"; free -h; printf "\n"; df -h /; fi; exec "${SHELL:-/bin/bash}" -l'
                ;;
            '󰆓  Create configuration backup')
                confirm 'Create configuration backup' && run_background 'Configuration backup' 'kalipwm backup'
                ;;
            '󰋚  List backups') show_report 'KaliPWM backups' 'kalipwm backups' ;;
            '󰁯  Repair dry-run') show_report 'Repair dry-run' 'kalipwm repair --dry-run' ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

diagnostics_menu() {
    local choice

    while true; do
        choice="$(choose 'Diagnostics' 'Read-only checks — no terminal windows' '󰒓  Run kalipwm doctor' '󰘳  Polybar log' '  Hardware summary' '󰈀  Network summary' '󰍹  Display summary' "$BACK")" || return 0
        case "$choice" in
            '󰒓  Run kalipwm doctor') show_report 'KaliPWM Doctor' 'kalipwm doctor' ;;
            '󰘳  Polybar log') show_report 'Polybar log' "if [ -f /tmp/polybar-obsidian-v2.log ]; then tail -n 120 /tmp/polybar-obsidian-v2.log; else printf 'Polybar log not found.\\n'; fi" ;;
            '  Hardware summary') show_report 'Hardware summary' "printf '=== Sensors ===\\n'; sensors 2>/dev/null || true; printf '\\n=== Graphics ===\\n'; lspci 2>/dev/null | grep -Ei 'VGA|3D|Display' || true; printf '\\n=== Power ===\\n'; for f in /sys/class/power_supply/BAT*/capacity; do [ -r \"\$f\" ] && printf '%s: %s%%\\n' \"\$f\" \"\$(cat \"\$f\")\"; done" ;;
            '󰈀  Network summary') show_report 'Network summary' "ip -brief address; printf '\\n'; ip route; printf '\\n'; command -v nmcli >/dev/null 2>&1 && nmcli connection show --active || true" ;;
            '󰍹  Display summary') show_report 'Display summary' 'xrandr --current' ;;
            "$BACK"|'') return 0 ;;
        esac
    done
}

main_menu() {
    local choice target_state vpn_if vpn_ip status

    while true; do
        target_state="$($TARGET_CMD 2>/dev/null || printf 'No Target')"
        vpn_if="$(find_vpn_interface)"
        vpn_ip=""
        [ -n "$vpn_if" ] && vpn_ip="$(ip -4 -o addr show dev "$vpn_if" scope global 2>/dev/null | awk '{print $4; exit}')"
        status="Target: $target_state  •  VPN: ${vpn_if:-off}${vpn_ip:+ $vpn_ip}"

        choice="$(choose 'KaliPWM' "$status" \
            '󰤨  Network' \
            '󰦝  VPN' \
            '  Target' \
            '󰸉  Wallpaper' \
            '󰹑  Screenshot' \
            '󰍹  Display' \
            '  Audio' \
            '  System' \
            '󰒓  Diagnostics' \
            '  Power')" || exit 0

        case "$choice" in
            '󰤨  Network') network_menu ;;
            '󰦝  VPN') vpn_menu ;;
            '  Target') target_menu ;;
            '󰸉  Wallpaper') wallpaper_menu ;;
            '󰹑  Screenshot') screenshot_menu ;;
            '󰍹  Display') display_menu ;;
            '  Audio') audio_menu ;;
            '  System') system_menu ;;
            '󰒓  Diagnostics') diagnostics_menu ;;
            '  Power') "$POWER_MENU"; exit 0 ;;
            '') exit 0 ;;
        esac
    done
}

case "${1:-main}" in
    main) main_menu ;;
    network) network_menu ;;
    vpn) vpn_menu ;;
    target) target_menu ;;
    wallpaper) wallpaper_menu ;;
    screenshot) screenshot_menu ;;
    display) display_menu ;;
    audio) audio_menu ;;
    system) system_menu ;;
    diagnostics|doctor) diagnostics_menu ;;
    power) "$POWER_MENU" ;;
    *)
        printf 'Unknown KaliPWM Control Center section: %s\n' "$1" >&2
        exit 2
        ;;
esac