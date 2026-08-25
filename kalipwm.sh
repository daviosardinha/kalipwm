#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_HELPER="$SCRIPT_DIR/SCRIPTS/kalipwm-state"
MODE="${1:-}"

case "$MODE" in
  --rollback)
    exec bash "$STATE_HELPER" rollback
    ;;
  --uninstall)
    exec bash "$STATE_HELPER" uninstall
    ;;
  --checkpoint)
    exec bash "$STATE_HELPER" checkpoint
    ;;
  --state-status)
    exec bash "$STATE_HELPER" status
    ;;
  --preflight|--detect-power|--help|-h)
    exec bash "$SCRIPT_DIR/install.sh" "$@"
    ;;
  '')
    bash "$STATE_HELPER" prepare
    exec bash "$SCRIPT_DIR/install.sh"
    ;;
  *)
    exec bash "$SCRIPT_DIR/install.sh" "$@"
    ;;
esac
