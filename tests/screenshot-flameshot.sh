#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/Pictures"
LOG="$TMP/flameshot.log"
CONFIG="$ROOT/CONFIGS/config/flameshot/flameshot.ini"

cat > "$TMP/bin/flameshot" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$KALIPWM_TEST_LOG"
exit 0
EOF
chmod +x "$TMP/bin/flameshot"

cat > "$TMP/bin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/bin/pgrep"

export PATH="$TMP/bin:$PATH"
export KALIPWM_TEST_LOG="$LOG"
export XDG_PICTURES_DIR="$TMP/Pictures"

bash "$ROOT/SCRIPTS/screenshot.sh" gui
bash "$ROOT/SCRIPTS/screenshot.sh" select
bash "$ROOT/SCRIPTS/screenshot.sh" full
bash "$ROOT/SCRIPTS/screenshot.sh" launcher
bash "$ROOT/SCRIPTS/screenshot.sh" screen

[[ "$(sed -n '1p' "$LOG")" == gui ]]
[[ "$(sed -n '2p' "$LOG")" == gui ]]
[[ "$(sed -n '3p' "$LOG")" == "full --path $TMP/Pictures/Screenshots" ]]
[[ "$(sed -n '4p' "$LOG")" == launcher ]]
[[ "$(sed -n '5p' "$LOG")" == "screen --path $TMP/Pictures/Screenshots" ]]
[[ -d "$TMP/Pictures/Screenshots" ]]

[[ -f "$CONFIG" ]]
grep -Fxq 'useX11LegacyScreenshot=true' "$CONFIG"
grep -Fxq 'saveAfterCopy=false' "$CONFIG"
grep -Fxq 'copyPathAfterSave=false' "$CONFIG"

# Fresh installs must carry the same known-good Flameshot config instead of
# requiring a post-install manual repair.
grep -Fq '.config/flameshot' "$ROOT/install.sh"
grep -Fq 'CONFIGS/config/flameshot' "$ROOT/install.sh"

echo 'screenshot-flameshot: PASS'
