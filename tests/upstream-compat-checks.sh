#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

printf '== Upstream BSPWM behavior preservation ==\n'

# V1 intentionally uses five canonical workspaces, but the general-purpose
# navigation/swap/history operations from upstream must remain available.
grep -A1 '^super + y$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'newest.marked.local'
grep -A1 '^super + g$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'biggest.window'
grep -A1 '^super + {p,b,comma,period}$' CONFIGS/config/sxhkd/sxhkdrc | grep -q '@{parent,brother,first,second}'
grep -A1 '^super + {_,shift + }c$' CONFIGS/config/sxhkd/sxhkdrc | grep -q '{next,prev}.local.!hidden.window'
grep -A3 '^super + {o,i}$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'bspc node {older,newer} -f'
grep -A1 '^super + {_,shift + }{1-5}$' CONFIGS/config/sxhkd/sxhkdrc | grep -q "'\^{1-5}'"
echo 'PASS upstream BSPWM navigation remains available with the V1 five-workspace model'

printf '\n== Resize helper behavior ==\n'
resize='CONFIGS/config/bspwm/scripts/bspwm_resize'
head -n1 "$resize" | grep -qx '#!/usr/bin/env bash'
grep -A1 '^super + alt + {Left,Down,Up,Right}$' CONFIGS/config/sxhkd/sxhkdrc | grep -q 'bash ~/.config/bspwm/scripts/bspwm_resize {west,south,north,east}'
grep -q 'chmod +x "\$HOME/.config/bspwm/scripts/bspwm_resize"' install.sh

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/bspc" <<'EOF'
#!/usr/bin/env bash
set -u
printf '%s\n' "$*" >> "$BSPC_LOG"
if [[ "${1:-}" == query ]]; then
  # Non-floating node => 100px tiled resize step.
  exit 1
fi
if [[ "${1:-}" == node && "${2:-}" == -z ]]; then
  count=0
  [[ -r "$BSPC_COUNT" ]] && read -r count < "$BSPC_COUNT"
  count=$((count + 1))
  printf '%s\n' "$count" > "$BSPC_COUNT"
  # Force the first edge to fail so the fallback edge is also exercised.
  (( count > 1 ))
  exit
fi
exit 0
EOF
chmod +x "$tmp/bspc"

check_resize() {
  local direction="$1" first="$2" second="$3"
  : > "$tmp/log"
  printf '0\n' > "$tmp/count"
  BSPC_LOG="$tmp/log" BSPC_COUNT="$tmp/count" PATH="$tmp:$PATH" bash "$resize" "$direction"
  grep -Fxq "$first" "$tmp/log"
  grep -Fxq "$second" "$tmp/log"
}

check_resize west  'node -z right -100 0' 'node -z left -100 0'
check_resize east  'node -z right 100 0'  'node -z left 100 0'
check_resize north 'node -z top 0 -100'   'node -z bottom 0 -100'
check_resize south 'node -z top 0 100'    'node -z bottom 0 100'
echo 'PASS resize helper preserves upstream primary/fallback split-boundary semantics'

printf '\n== Upstream application rules ==\n'
for rule in \
  "bspc rule -a Gimp state=floating follow=on" \
  "bspc rule -a Chromium desktop='II'" \
  "bspc rule -a mplayer2 state=floating" \
  "bspc rule -a Kupfer.py focus=on" \
  "bspc rule -a Screenkey manage=off"; do
  grep -Fqx "$rule" CONFIGS/config/bspwm/bspwmrc
done
echo 'PASS safe upstream application behavior is retained'

printf '\n== Kitty workflow preservation ==\n'
grep -Fqx 'map F1 copy_to_buffer a' CONFIGS/config/kitty/kitty.conf
grep -Fqx 'map F2 paste_from_buffer a' CONFIGS/config/kitty/kitty.conf
grep -Fqx 'map F3 copy_to_buffer b' CONFIGS/config/kitty/kitty.conf
grep -Fqx 'map F4 paste_from_buffer b' CONFIGS/config/kitty/kitty.conf
echo 'PASS upstream Kitty named buffers remain available'

printf '\n== Audio helper behavior ==\n'
cat > "$tmp/wpctl" <<'EOF'
#!/usr/bin/env bash
set -u
if [[ "${1:-}" == get-volume ]]; then
  printf '%s\n' "${WPCTL_OUTPUT:-Volume: 0.42}"
  exit 0
fi
printf '%s\n' "$*" >> "$AUDIO_LOG"
EOF
chmod +x "$tmp/wpctl"

audio_out="$(WPCTL_OUTPUT='Volume: 0.42' AUDIO_LOG="$tmp/audio-log" PATH="$tmp:$PATH" bash SCRIPTS/kalipwm-audio status)"
[[ "$audio_out" == '42%' ]]
audio_out="$(WPCTL_OUTPUT='Volume: 0.42 [MUTED]' AUDIO_LOG="$tmp/audio-log" PATH="$tmp:$PATH" bash SCRIPTS/kalipwm-audio status)"
[[ "$audio_out" == 'MUTE' ]]
: > "$tmp/audio-log"
AUDIO_LOG="$tmp/audio-log" PATH="$tmp:$PATH" bash SCRIPTS/kalipwm-audio up
grep -Fxq 'set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+' "$tmp/audio-log"
AUDIO_LOG="$tmp/audio-log" PATH="$tmp:$PATH" bash SCRIPTS/kalipwm-audio mute
grep -Fxq 'set-mute @DEFAULT_AUDIO_SINK@ toggle' "$tmp/audio-log"
echo 'PASS audio status and controls target the dynamic default PipeWire sink'

printf '\n== Polybar behavior preservation ==\n'
right="$(grep '^modules-right =' CONFIGS/config/polybar/forest/config.ini)"
for module in cpu memory telemetry network-status vpn-status battery-status audio-status date sysmenu; do
  grep -qw "$module" <<< "$right"
done
grep -q '^\[module/audio-status\]$' CONFIGS/config/polybar/forest/user_modules.ini
grep -q '^exec = ~/.local/bin/kalipwm-audio status$' CONFIGS/config/polybar/forest/user_modules.ini
grep -q '^scroll-up = ~/.local/bin/kalipwm-audio up$' CONFIGS/config/polybar/forest/user_modules.ini
grep -q '^scroll-down = ~/.local/bin/kalipwm-audio down$' CONFIGS/config/polybar/forest/user_modules.ini
grep -qw 'pavucontrol' install.sh
launcher_block="$(awk '/^\[module\/launcher\]/{on=1; next} /^\[module\//{if(on) exit} on{print}' CONFIGS/config/polybar/forest/user_modules.ini)"
! grep -q 'style-switch' <<< "$launcher_block"
! grep -q 'sed -i' CONFIGS/config/polybar/forest/scripts/style-switch.sh
! grep -q 'sed -i' CONFIGS/config/polybar/forest/scripts/styles.sh
grep -q 'fixed Obsidian Tactical palette' CONFIGS/config/polybar/forest/scripts/style-switch.sh
echo 'PASS CPU/RAM/audio visibility is restored and legacy palette scripts cannot corrupt V1 colors'

printf '\n== Intentional V1 divergences remain protected ==\n'
! grep -RInE 'Virtual1|--mode[[:space:]]+1920x1080' CONFIGS SCRIPTS install.sh kalipwm.sh >/dev/null
! grep -nEi '^bspc rule -a .*vmware.*desktop=' CONFIGS/config/bspwm/bspwmrc >/dev/null
grep -q 'if \[\[ "\$environment" == vmware \]\]; then' CONFIGS/config/bspwm/bspwmrc
grep -q 'picom --config /dev/null --backend xrender' CONFIGS/config/bspwm/bspwmrc
! grep -Eq 'alias[[:space:]]+(cat|vim)=' CONFIGS/zshrc
grep -Fqx 'export EDITOR=vim' CONFIGS/zshrc
echo 'PASS adaptive display/VMware handling and Vim/cat policy remain intentional V1 improvements'

printf '\nAll upstream compatibility checks passed.\n'
