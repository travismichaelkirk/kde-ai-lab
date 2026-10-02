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

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=../lib/android-device.sh
source "$SCRIPT_DIR/../lib/android-device.sh"

kde_ai_lab_select_android_device || exit 1

device="$ANDROID_DEVICE"

case "$ANDROID_TRANSPORT" in
    "Wireless Debugging")
        log "using connected Wireless Debugging device"
        ;;
    "USB")
        log "using USB fallback"
        ;;
esac

model="$(
    adb -s "$device" shell getprop ro.product.model |
    tr -d '\r'
)"

log "ADB device: $device${model:+ ($model)}"
log "starting scrcpy"

exec "$SCRCPY" -s "$device"
