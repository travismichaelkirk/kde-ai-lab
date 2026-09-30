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

wireless_device="$(
    adb mdns services 2>/dev/null |
    awk '$2 == "_adb-tls-connect._tcp" { print $3; exit }'
)"

device=""

if [[ -n "$wireless_device" ]]; then
    log "Wireless Debugging discovered: $wireless_device"

    adb connect "$wireless_device" >/dev/null 2>&1 || true

    if adb devices |
        awk -v device="$wireless_device" '
            $1 == device && $2 == "device" { found = 1 }
            END { exit !found }
        '
    then
        device="$wireless_device"
        log "using Wireless Debugging"
    else
        log "Wireless Debugging endpoint is not authorized; checking USB"
    fi
fi

if [[ -z "$device" ]]; then
    usb_devices="$(
        adb devices -l |
        awk '
            NR > 1 &&
            $2 == "device" &&
            $0 ~ / usb:/ {
                print $1
            }
        '
    )"

    usb_count="$(
        printf '%s\n' "$usb_devices" |
        awk 'NF { count++ } END { print count + 0 }'
    )"

    case "$usb_count" in
        0)
            fail "no usable Wireless Debugging or USB ADB device found"
            ;;
        1)
            device="$usb_devices"
            log "using USB fallback"
            ;;
        *)
            fail "multiple USB ADB devices found; automatic selection is unsafe"
            ;;
    esac
fi

model="$(
    adb -s "$device" shell getprop ro.product.model |
    tr -d '\r'
)"

log "ADB device: $device${model:+ ($model)}"
log "starting scrcpy"

exec "$SCRCPY" -s "$device"
