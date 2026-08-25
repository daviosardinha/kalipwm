#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STATE_HELPER="$SCRIPT_DIR/SCRIPTS/kalipwm-state"
MODE="${1:-}"

bspwm_socket_for_pid() {
  local pid="$1" fd link inode socket

  [[ -r "/proc/$pid/fd" || -d "/proc/$pid/fd" ]] || return 1
  for fd in /proc/"$pid"/fd/*; do
    link="$(readlink "$fd" 2>/dev/null || true)"
    case "$link" in
      socket:\[*\]) inode="${link#socket:[}"; inode="${inode%]}" ;;
      *) continue ;;
    esac
    socket="$(awk -v inode="$inode" '$7 == inode && NF >= 8 && $8 ~ /bspwm/ {print $8; exit}' /proc/net/unix 2>/dev/null)"
    if [[ -n "$socket" ]]; then
      printf '%s\n' "$socket"
      return 0
    fi
  done
  return 1
}

end_stale_bspwm_session() {
  local pid socket

  pid="$(pgrep -u "$UID" -x bspwm 2>/dev/null | head -1 || true)"
  [[ -n "$pid" ]] || return 0

  printf '[*] KaliPWM was uninstalled while BSPWM is still active; ending the stale desktop session.\n'
  socket="$(bspwm_socket_for_pid "$pid" || true)"

  if [[ -n "$socket" ]] && command -v bspc >/dev/null 2>&1; then
    BSPWM_SOCKET="$socket" bspc quit >/dev/null 2>&1 || kill -TERM "$pid" 2>/dev/null || true
  else
    kill -TERM "$pid" 2>/dev/null || true
  fi

  printf '[+] BSPWM session ended. LightDM should return to the login screen; select your restored desktop session.\n'
}

case "$MODE" in
  --rollback)
    exec bash "$STATE_HELPER" rollback
    ;;
  --uninstall)
    bash "$STATE_HELPER" uninstall
    end_stale_bspwm_session
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
