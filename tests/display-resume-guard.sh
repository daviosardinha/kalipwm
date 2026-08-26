#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
script='SCRIPTS/kalipwm-display'

printf '== Display resume fail-safe ==\n'

# Geometry must be part of the topology state so connected-but-inactive outputs
# are visible to the watcher.
grep -q '^topology_signature()' "$script"
grep -q '\${geometry:-inactive}' "$script"

# An already-active eDP panel must not be repeatedly modeset with --auto while
# an external provider output is failing.
grep -A8 'Avoid needlessly modesetting an already-active laptop panel' "$script" \
  | grep -q 'xrandr --output "\$internal" --primary'

# Recovery is edge-triggered by an actual topology/geometry transition. Never
# reintroduce a timer-based retry loop that can blank the laptop panel forever.
! grep -q 'last_recovery' "$script"
! grep -q 'display_needs_recovery' "$script"
grep -A20 '^    if \[\[ "\$current" != "\$previous" \]\]; then' "$script" \
  | grep -q '^      apply_all true$'
grep -A20 '^    if \[\[ "\$current" != "\$previous" \]\]; then' "$script" \
  | grep -q 'previous="$(topology_signature)"'

echo 'PASS resume recovery attempts once per topology transition and fails safe'
