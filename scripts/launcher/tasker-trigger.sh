#!/usr/bin/env bash

set -euo pipefail

log() {
    printf 'kde-ai-lab-tasker: %s\n' "$*"
}

fail() {
    printf 'kde-ai-lab-tasker: ERROR: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=../lib/android-device.sh
source "$SCRIPT_DIR/../lib/android-device.sh"

command -v curl >/dev/null 2>&1 ||
    fail "curl is not installed"

kde_ai_lab_select_android_device || exit 1

device="$ANDROID_DEVICE"

pixel_ip="$(
    adb -s "$device" shell ip -4 addr show wlan0 2>/dev/null |
        awk '/^[[:space:]]*inet / {
            split($2, address, "/")
            print address[1]
            exit
        }' |
        tr -d '\r'
)"

[[ -n "$pixel_ip" ]] ||
    fail "unable to determine Android Wi-Fi IPv4 address"

log "ADB device: $device"
log "Wi-Fi address: $pixel_ip"
log "triggering Tasker HTTP bridge"

curl \
    --silent \
    --show-error \
    --connect-timeout 5 \
    "http://${pixel_ip}:8765/"

log "Tasker HTTP request completed"
