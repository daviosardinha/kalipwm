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
old = '''# Volume
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
new = '''# Volume
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
if old not in src:
    raise SystemExit('expected upstream media-key block not found')
Path(sys.argv[2]).write_text(src.replace(old, new, 1))
PY

if ! cmp -s "$EXPECTED" "$CURRENT"; then
  echo 'sxhkdrc differs from upstream beyond the approved media-key block' >&2
  diff -u "$EXPECTED" "$CURRENT" || true
  exit 1
fi

for token in \
  XF86AudioRaiseVolume \
  XF86AudioLowerVolume \
  XF86AudioMute \
  'XF86MonBrightness{Up,Down}' \
  kalipwm-audio \
  kalipwm-brightness \
  kalipwm-osd; do
  grep -Fq "$token" "$CURRENT"
done

echo 'sxhkd-media-bindings: PASS'
