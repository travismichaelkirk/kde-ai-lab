#!/usr/bin/env bash

# Shared Android ADB device selection for KDE AI Lab.
#
# On success:
#   ANDROID_DEVICE     selected ADB serial/endpoint
#   ANDROID_TRANSPORT  "Wireless Debugging" or "USB"

kde_ai_lab_select_android_device() {
    command -v adb >/dev/null 2>&1 || {
        printf 'ERROR: adb is not installed\n' >&2
        return 1
    }

    ANDROID_DEVICE=""
    ANDROID_TRANSPORT=""

    local connected_wireless=""
    local wireless_endpoint=""
    local usb_devices=""
    local usb_count=""

    # Prefer an already-connected Wireless Debugging device.
    connected_wireless="$(
        adb devices |
        awk '
            NR > 1 &&
            $2 == "device" &&
            $1 ~ /_adb-tls-connect\._tcp$/ {
                print $1
                exit
            }
        '
    )"

    if [[ -n "$connected_wireless" ]]; then
        ANDROID_DEVICE="$connected_wireless"
        ANDROID_TRANSPORT="Wireless Debugging"
        return 0
    fi

    # If no wireless device is already connected, discover one with mDNS.
    wireless_endpoint="$(
        adb mdns services 2>/dev/null |
        awk '$2 == "_adb-tls-connect._tcp" { print $3; exit }'
    )"

    if [[ -n "$wireless_endpoint" ]]; then
        adb connect "$wireless_endpoint" >/dev/null 2>&1 || true

        connected_wireless="$(
            adb devices |
            awk '
                NR > 1 &&
                $2 == "device" &&
                $1 ~ /_adb-tls-connect\._tcp$/ {
                    print $1
                    exit
                }
            '
        )"

        if [[ -n "$connected_wireless" ]]; then
            ANDROID_DEVICE="$connected_wireless"
            ANDROID_TRANSPORT="Wireless Debugging"
            return 0
        fi
    fi

    # Final fallback: a single USB ADB device.
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
            printf \
                'ERROR: no usable Wireless Debugging or USB ADB device found\n' \
                >&2
            return 1
            ;;
        1)
            ANDROID_DEVICE="$usb_devices"
            ANDROID_TRANSPORT="USB"
            return 0
            ;;
        *)
            printf \
                'ERROR: multiple USB ADB devices found; automatic selection is unsafe\n' \
                >&2
            return 1
            ;;
    esac
}
