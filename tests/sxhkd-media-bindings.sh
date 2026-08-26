#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BASE=187eefe3108040f8d0f1164804ac3f0267113604
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BASELINE="$TMP/sxhkdrc.baseline"
EXPECTED="$TMP/sxhkdrc.expected"
CURRENT="$ROOT/CONFIGS/config/sxhkd/sxhkdrc"

git -C "$ROOT" show "$BASE:CONFIGS/config/sxhkd/sxhkdrc" > "$BASELINE"

python3 - "$BASELINE" "$EXPECTED" <<'PY'
from pathlib import Path
import sys

src = Path(sys.argv[1]).read_text()

old_screenshot = '''@Print
        screenshot select

@Print + ctrl
        screenshot

@Print + alt
        screenshot window
'''
new_screenshot = '''# Interactive region + annotation. Ctrl+C inside Flameshot copies the
# selection to the clipboard without saving it automatically.
Print
\tbash ~/.config/polybar/forest/scripts/screenshot.sh gui

# Ctrl is a Flameshot in-GUI modifier too. Trigger this binding on Print
# release and add a tiny grace period so the launch does not inherit the
# shortcut modifier state.
ctrl + @Print
\tsleep 0.20; bash ~/.config/polybar/forest/scripts/screenshot.sh gui

# Explicit full-desktop save to ~/Pictures/Screenshots.
shift + Print
\tbash ~/.config/polybar/forest/scripts/screenshot.sh full
'''

old_media = '''# Volume
#XF86AudioRaiseVolume
#    pactl set-sink-volume 0 +5%
#XF86AudioLowerVolume
#    pactl set-sink-volume 0 -5%
#XF86AudioMute
#    pactl set-sink-mute 0 toggle

# Screen Brightness
#XF86MonBrightness{Up,Down}  
#    brightnessctl -c backlight s 10{+,-}
'''
new_media = '''# Volume
XF86AudioRaiseVolume
\tbash ~/.config/polybar/forest/scripts/kalipwm-audio up && bash ~/.config/polybar/forest/scripts/kalipwm-osd volume

XF86AudioLowerVolume
\tbash ~/.config/polybar/forest/scripts/kalipwm-audio down && bash ~/.config/polybar/forest/scripts/kalipwm-osd volume

XF86AudioMute
\tbash ~/.config/polybar/forest/scripts/kalipwm-audio mute && bash ~/.config/polybar/forest/scripts/kalipwm-osd volume

# Screen Brightness
XF86MonBrightness{Up,Down}
\tbash ~/.config/polybar/forest/scripts/kalipwm-brightness {up,down} && bash ~/.config/polybar/forest/scripts/kalipwm-osd brightness
'''

if old_screenshot not in src:
    raise SystemExit('expected upstream screenshot block not found')
src = src.replace(old_screenshot, new_screenshot, 1)

if old_media not in src:
    raise SystemExit('expected upstream media-key block not found')
src = src.replace(old_media, new_media, 1)

Path(sys.argv[2]).write_text(src)
PY

if ! cmp -s "$EXPECTED" "$CURRENT"; then
  echo 'sxhkdrc differs from upstream beyond approved screenshot/media-key blocks' >&2
  diff -u "$EXPECTED" "$CURRENT" || true
  exit 1
fi

for token in \
  'Print' \
  'ctrl + @Print' \
  'sleep 0.20; bash ~/.config/polybar/forest/scripts/screenshot.sh gui' \
  'shift + Print' \
  'screenshot.sh gui' \
  'screenshot.sh full' \
  XF86AudioRaiseVolume \
  XF86AudioLowerVolume \
  XF86AudioMute \
  'XF86MonBrightness{Up,Down}' \
  kalipwm-audio \
  kalipwm-brightness \
  kalipwm-osd; do
  grep -Fq "$token" "$CURRENT"
done

echo 'sxhkd-approved-bindings: PASS'
