#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

set +e
output="$({
    HOME="$TMP/home" \
    XDG_CACHE_HOME="$TMP/cache" \
    KALIPWM_TEST_FAIL_STAGE="installer failure self-test" \
    TERM=dumb \
    bash "$ROOT/kalipwm.sh"
} 2>&1)"
rc=$?
set -e

if [ "$rc" -eq 0 ]; then
    printf '%s\n' 'installer failure self-test unexpectedly succeeded' >&2
    exit 1
fi

for token in \
    'KaliPWM installation stopped.' \
    'Stage: installer failure self-test' \
    'Failure: line ' \
    'No automatic rollback was attempted; existing files were left as-is.' \
    'Fix the reported problem, then rerun:'; do
    if ! grep -Fq "$token" <<<"$output"; then
        printf 'missing installer failure token: %s\n' "$token" >&2
        printf '%s\n' "$output" >&2
        exit 1
    fi
done

if grep -Fq '[+] KaliPWM environment deployed.' <<<"$output"; then
    printf '%s\n' 'installer printed success after injected failure' >&2
    exit 1
fi

printf '%s\n' 'installer-failure-handling: PASS'
