#!/usr/bin/env bash

set -euo pipefail

SCRCPY_HOME="$HOME/.local/lib/kde-ai-lab/scrcpy-4.1"
SCRCPY="$SCRCPY_HOME/scrcpy"

log() {
    printf 'kde-ai-lab-android: %s\n' "$*"
}

fail() {
    printf 'kde-ai-lab-android: ERROR: %s\n' "$*" >&2
    exit 1
}

[[ -x "$SCRCPY" ]] ||
    fail "scrcpy executable not found: $SCRCPY"

command -v adb >/dev/null 2>&1 ||
    fail "adb is not installed"

device_count="$(
    adb devices |
    awk 'NR > 1 && $2 == "device" { count++ } END { print count + 0 }'
)"

case "$device_count" in
    0)
        fail "no authorized ADB device found"
        ;;
    1)
        ;;
    *)
        fail "multiple authorized ADB devices found; automatic selection is unsafe"
        ;;
esac

device="$(
    adb devices |
    awk 'NR > 1 && $2 == "device" { print $1; exit }'
)"

model="$(
    adb -s "$device" shell getprop ro.product.model |
    tr -d '\r'
)"

log "ADB device: $device${model:+ ($model)}"
log "starting scrcpy"

exec "$SCRCPY" -s "$device"
