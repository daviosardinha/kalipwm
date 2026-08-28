#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/home/.config/flameshot" "$TMP/bin"
cat >"$TMP/home/.config/flameshot/flameshot.ini" <<'EOF'
[General]
showStartupLaunchMessage=false
useX11LegacyScreenshot=false
EOF

cat >"$TMP/bin/flameshot" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${FLAMESHOT_TEST_ARGS:?}"
EOF
chmod +x "$TMP/bin/flameshot"

HOME="$TMP/home" \
DISPLAY=:99 \
XDG_SESSION_TYPE=x11 \
PATH="$TMP/bin:$PATH" \
FLAMESHOT_TEST_ARGS="$TMP/args" \
    bash "$ROOT/SCRIPTS/screenshot.sh" select

config="$TMP/home/.config/flameshot/flameshot.ini"
grep -Fxq 'useX11LegacyScreenshot=true' "$config"
grep -Fxq 'showStartupLaunchMessage=false' "$config"
grep -Fxq 'gui' "$TMP/args"

printf '%s\n' 'flameshot-x11-regression: PASS'
