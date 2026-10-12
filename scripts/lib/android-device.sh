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

    local usb_devices=""
    local usb_count=""

    # Prefer the designated Pixel when its Wireless ADB connection
    # is already active and its serial number has been verified.
    local selection_status=0

    kde_ai_lab_select_verified_wireless_device || selection_status=$?

    case "$selection_status" in
        0)
            return 0
            ;;
        1)
            # No verified wireless connection; recovery may be attempted.
            ;;
        *)
            # ADB failure: do not attempt recovery or USB fallback.
            return "$selection_status"
            ;;
    esac

    # Recover Wireless Debugging using the existing v0.8 manager.
    # Resolve the script relative to this library, not the working directory.
    local recovery_script=""
    recovery_script="$(
        cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../diagnostics" &&
        pwd
    )/adb-connect.sh"

    if [[ -x "$recovery_script" ]]; then
        if bash "$recovery_script" >/dev/null 2>&1; then
            selection_status=0
            kde_ai_lab_select_verified_wireless_device || selection_status=$?

            case "$selection_status" in
                0)
                    return 0
                    ;;
                1)
                    # Recovery did not produce a verified wireless device.
                    ;;
                *)
                    # ADB failure: do not attempt USB fallback.
                    return "$selection_status"
                    ;;
            esac
        fi
    fi

    # Final fallback: a single USB ADB device.
    # Do not mistake an ADB enumeration failure for an empty device list.
    local usb_adb_list=""

    usb_adb_list="$(timeout 10 adb devices -l)" || {
        printf 'ERROR: unable to enumerate USB ADB devices\n' >&2
        return 2
    }

    usb_devices="$(
        printf '%s\n' "$usb_adb_list" |
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
            local actual_serial=""

            actual_serial="$(
                timeout 5 adb -s "$usb_devices" shell getprop ro.serialno 2>/dev/null
            )" || {
                printf 'ERROR: unable to verify USB device identity\n' >&2
                return 1
            }

            actual_serial="${actual_serial//$'\r'/}"

            if [[ "$actual_serial" != "67140DLKX00137" ]]; then
                printf 'ERROR: USB device serial does not match designated Pixel\n' >&2
                return 1
            fi

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

# Select an already-connected, verified Pixel Wireless ADB transport.
# This function does not initiate discovery or change ADB connections.
# shellcheck disable=SC2034
kde_ai_lab_select_verified_wireless_device() {
    local expected_serial="67140DLKX00137"
    local transport=""
    local state=""
    local actual_serial=""
    local adb_list=""

    command -v adb >/dev/null 2>&1 || {
        printf 'ERROR: adb is not installed\n' >&2
        return 2
    }

    ANDROID_DEVICE=""
    ANDROID_TRANSPORT=""

    adb_list="$(timeout 10 adb devices)" || {
        printf 'ERROR: unable to enumerate ADB devices\n' >&2
        return 2
    }

    while read -r transport state _; do
        [[ "$state" == "device" ]] || continue

        # Consider TLS mDNS names and IPv4:port transports.
        if [[ "$transport" != *._adb-tls-connect._tcp &&
              ! "$transport" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
            continue
        fi

        actual_serial="$(
            timeout 5 adb -s "$transport" shell getprop ro.serialno 2>/dev/null
        )" || continue

        actual_serial="${actual_serial//$'\r'/}"

        if [[ "$actual_serial" == "$expected_serial" ]]; then
            ANDROID_DEVICE="$transport"
            ANDROID_TRANSPORT="Wireless Debugging"
            return 0
        fi
    done <<< "$adb_list"

    return 1
}
