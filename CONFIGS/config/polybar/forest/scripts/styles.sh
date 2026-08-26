#!/usr/bin/env bash
set -u

# Compatibility shim retained for users/scripts that still call the upstream
# styles.sh entry point. V1 intentionally supports only Obsidian Tactical; the
# old palette writer is disabled because it knows nothing about V1 semantic
# colors and could partially corrupt the active theme.

case "${1:-}" in
  --obsidian|--default|--nord|--gruvbox|--dark|--cherry|'')
    printf '%s\n' 'KaliPWM V1 palette switching is disabled; Obsidian Tactical remains active.'
    exit 0
    ;;
  *)
    printf 'Usage: %s [--obsidian]\n' "$0" >&2
    exit 2
    ;;
esac
