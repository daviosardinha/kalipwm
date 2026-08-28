#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
LOCK="$ROOT/DEPENDENCIES.lock"
INSTALLER="$ROOT/kalipwm.sh"
KITTY_INSTALLER="$ROOT/kitty-installer.sh"

bash -n "$LOCK"
sh -n "$KITTY_INSTALLER"

# shellcheck disable=SC1090
. "$LOCK"

git_refs=(
    "$OH_MY_ZSH_REF"
    "$POWERLEVEL10K_REF"
    "$ZSH_AUTOSUGGESTIONS_REF"
    "$ZSH_SYNTAX_HIGHLIGHTING_REF"
    "$FZF_REF"
    "$TMUX_REF"
    "$POLYBAR_REF"
    "$POLYBAR_THEMES_REF"
    "$PICOM_REF"
)

for ref in "${git_refs[@]}"; do
    [[ "$ref" =~ ^[0-9a-f]{40}$ ]] || {
        printf 'invalid locked Git revision: %s\n' "$ref" >&2
        exit 1
    }
done

[[ "$KITTY_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$KITTY_SHA256_X86_64" =~ ^[0-9a-f]{64}$ ]]
[[ "$KITTY_SHA256_ARM64" =~ ^[0-9a-f]{64}$ ]]
[[ "$NERD_FONT_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]

if grep -Fq 'raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh' "$INSTALLER"; then
    printf '%s\n' 'unlocked Oh My Zsh remote installer returned' >&2
    exit 1
fi

for variable in \
    OH_MY_ZSH_REF \
    POWERLEVEL10K_REF \
    ZSH_AUTOSUGGESTIONS_REF \
    ZSH_SYNTAX_HIGHLIGHTING_REF \
    FZF_REF \
    TMUX_REF \
    POLYBAR_REF \
    POLYBAR_THEMES_REF \
    PICOM_REF; do
    grep -Fq "\$$variable" "$INSTALLER" || {
        printf 'installer does not consume dependency lock variable: %s\n' "$variable" >&2
        exit 1
    }
done

grep -Fq 'KITTY_VERSION="$KITTY_VERSION" KITTY_SHA256="$kitty_bundle_sha256"' "$INSTALLER"
grep -Fq 'Verified kitty SHA-256' "$KITTY_INSTALLER"

printf '%s\n' 'dependency-lock: PASS'
