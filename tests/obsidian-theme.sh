#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export KALIPWM_STATE_ROOT="$TMP/state"
export KALIPWM_THEME_NO_RESTART=1
mkdir -p \
  "$HOME/.config/bspwm" \
  "$HOME/.config/polybar/forest/scripts/rofi" \
  "$HOME/.config/kitty" \
  "$HOME/.config/dunst"

cat > "$HOME/.config/bspwm/bspwmrc" <<'EOF'
#!/bin/sh
bspc config border_width 0
bspc config window_gap 12
EOF
chmod +x "$HOME/.config/bspwm/bspwmrc"

cat > "$HOME/.config/polybar/forest/colors.ini" <<'EOF'
[color]
background = #212B30
foreground = #C4C7C5
EOF

cat > "$HOME/.config/polybar/forest/config.ini" <<'EOF'
[bar/main]
height = 48
padding = 2
modules-right = cpu memory kalipwm-audio kalipwm-battery date
EOF

cat > "$HOME/.config/kitty/color.ini" <<'EOF'
foreground #ffffff
background #000000
EOF

cat > "$HOME/.config/kitty/kitty.conf" <<'EOF'
window_padding_width 0
include color.ini
url_color #61afef
active_tab_background #98c379
inactive_tab_background #e06c75
inactive_tab_foreground #000000
tab_bar_margin_color black
background_opacity 0.85
EOF

cat > "$HOME/.config/polybar/forest/scripts/rofi/launcher.rasi" <<'EOF'
window { width: 100%; }
EOF

cat > "$HOME/.config/dunst/dunstrc" <<'EOF'
[global]
background = "#000000"
EOF

bash "$ROOT/SCRIPTS/kalipwm-theme" apply > "$TMP/apply.out"

grep -Fxq 'theme=obsidian-tactical' "$TMP/apply.out"
grep -Fxq 'bspwm_visual=active' "$TMP/apply.out"
grep -Fxq 'picom_visual=preserved_for_compatibility' "$TMP/apply.out"

grep -Fq '# >>> kalipwm-obsidian-tactical >>>' "$HOME/.config/bspwm/bspwmrc"
grep -Fq "bspc config window_gap 9" "$HOME/.config/bspwm/bspwmrc"
grep -Fq "bspc config focused_border_color '#9B7EDE'" "$HOME/.config/bspwm/bspwmrc"
[[ "$(grep -Fc '# >>> kalipwm-obsidian-tactical >>>' "$HOME/.config/bspwm/bspwmrc")" -eq 1 ]]

grep -Fq 'background = #EE0F1117' "$HOME/.config/polybar/forest/colors.ini"
grep -Fq 'accent = #9B7EDE' "$HOME/.config/polybar/forest/colors.ini"
grep -Fxq 'height = 38' "$HOME/.config/polybar/forest/config.ini"
grep -Fxq 'padding = 1' "$HOME/.config/polybar/forest/config.ini"
grep -Fxq 'modules-right = cpu memory kalipwm-audio kalipwm-battery date' "$HOME/.config/polybar/forest/config.ini"

grep -Fq 'background #0F1117' "$HOME/.config/kitty/color.ini"
grep -Fxq 'window_padding_width 8' "$HOME/.config/kitty/kitty.conf"
grep -Fxq 'background_opacity 0.94' "$HOME/.config/kitty/kitty.conf"
grep -Fxq 'active_tab_background #292438' "$HOME/.config/kitty/kitty.conf"
grep -Fxq 'inactive_tab_foreground #9298A6' "$HOME/.config/kitty/kitty.conf"

grep -Fq 'Obsidian Tactical Rofi launcher' "$HOME/.config/polybar/forest/scripts/rofi/launcher.rasi"
grep -Fq 'background:       #0F1117F2;' "$HOME/.config/polybar/forest/scripts/rofi/launcher.rasi"
grep -Fq 'Obsidian Tactical Dunst' "$HOME/.config/dunst/dunstrc"
grep -Fq 'frame_color = "#9B7EDE"' "$HOME/.config/dunst/dunstrc"

# Applying twice must remain idempotent and keep one BSPWM visual marker block.
bash "$ROOT/SCRIPTS/kalipwm-theme" apply >/dev/null
[[ "$(grep -Fc '# >>> kalipwm-obsidian-tactical >>>' "$HOME/.config/bspwm/bspwmrc")" -eq 1 ]]

status="$(bash "$ROOT/SCRIPTS/kalipwm-theme" status)"
grep -Fxq 'bspwm_visual=active' <<<"$status"
grep -Fxq 'polybar_visual=active' <<<"$status"
grep -Fxq 'kitty_visual=active' <<<"$status"
grep -Fxq 'rofi_visual=active' <<<"$status"
grep -Fxq 'dunst_visual=active' <<<"$status"
grep -Fxq 'picom_visual=preserved_for_compatibility' <<<"$status"

find "$TMP/state/theme-backups" -type f | grep -q .

echo 'obsidian-theme: PASS'
