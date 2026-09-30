#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '%s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

command -v adb >/dev/null 2>&1 ||
    fail "adb is not installed"

wireless_device="$(
    adb mdns services 2>/dev/null |
    awk '$2 == "_adb-tls-connect._tcp" { print $3; exit }'
)"

device=""
transport=""

if [[ -n "$wireless_device" ]]; then
    adb connect "$wireless_device" >/dev/null 2>&1 || true

    if adb devices |
        awk -v device="$wireless_device" '
            $1 == device && $2 == "device" { found = 1 }
            END { exit !found }
        '
    then
        device="$wireless_device"
        transport="Wireless Debugging"
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
            transport="USB"
            ;;
        *)
            fail "multiple USB ADB devices found"
            ;;
    esac
fi

current_user="$(
    adb -s "$device" shell am get-current-user |
    tr -d '\r'
)"

model="$(
    adb -s "$device" shell getprop ro.product.model |
    tr -d '\r'
)"

android_version="$(
    adb -s "$device" shell getprop ro.build.version.release |
    tr -d '\r'
)"

sdk="$(
    adb -s "$device" shell getprop ro.build.version.sdk |
    tr -d '\r'
)"

if adb -s "$device" shell \
    "pm list packages --user $current_user" 2>/dev/null |
    grep -q '^package:net.dinglisch.android.taskerm$'
then
    tasker_installed="Yes"
else
    tasker_installed="No"
fi

if adb -s "$device" shell \
    "ps -A -o NAME 2>/dev/null" |
    grep -q '^net\.dinglisch\.android\.taskerm$'
then
    tasker_process="Active"
else
    tasker_process="Inactive"
fi

notification_listeners="$(
    adb -s "$device" shell         settings get secure enabled_notification_listeners |
    tr -d '\r'
)"

if grep -q 'net\.dinglisch\.android\.taskerm.*NotificationListenerService'     <<<"$notification_listeners"
then
    tasker_notification_access="Enabled"
else
    tasker_notification_access="Disabled"
fi

accessibility_services="$(
    adb -s "$device" shell         settings get secure enabled_accessibility_services |
    tr -d '\r'
)"

if grep -q 'net\.dinglisch\.android\.taskerm.*MyAccessibilityService'     <<<"$accessibility_services"
then
    tasker_accessibility="Enabled"
else
    tasker_accessibility="Disabled"
fi

resumed_activity="$(
    adb -s "$device" shell dumpsys activity activities |
    grep -m1 'ResumedActivity:' || true
)"

if grep -q 'net\.dinglisch\.android\.taskerm/' <<<"$resumed_activity"
then
    tasker_foreground="Yes"
else
    tasker_foreground="No"
fi

printf '\n'
printf 'KDE AI LAB — ANDROID DIAGNOSTICS\n'
printf '%s\n' '================================'

printf '\nADB\n'
printf '  Transport:       %s\n' "$transport"
printf '  Endpoint:        %s\n' "$device"
printf '  Device:          %s\n' "$model"
printf '  Android:         %s\n' "$android_version"
printf '  SDK:             %s\n' "$sdk"
printf '  Android user:    %s\n' "$current_user"

printf '\nTASKER\n'
printf '  Installed:       %s\n' "$tasker_installed"
printf '  Process:         %s\n' "$tasker_process"
printf '  Foreground:      %s\n' "$tasker_foreground"

printf '\nTASKER INTEGRATION\n'
printf '  Notification access:  %s\n' "$tasker_notification_access"
printf '  Accessibility:        %s\n' "$tasker_accessibility"

printf '\n'
