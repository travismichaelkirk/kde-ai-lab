#!/usr/bin/env bash

set -euo pipefail

log() {
    printf '%s\n' "$*"
}

fail() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=../lib/android-device.sh
source "$SCRIPT_DIR/../lib/android-device.sh"

kde_ai_lab_select_android_device || exit 1

device="$ANDROID_DEVICE"
transport="$ANDROID_TRANSPORT"

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

tasker_services="$(
    adb -s "$device" shell         dumpsys activity services net.dinglisch.android.taskerm 2>/dev/null
)"

if grep -q     'net\.dinglisch\.android\.taskerm/\.MonitorService'     <<<"$tasker_services"
then
    tasker_automation="Enabled"
else
    tasker_automation="Disabled"
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
printf '  Automation:      %s\n' "$tasker_automation"
printf '  Process:         %s\n' "$tasker_process"
printf '  Foreground:      %s\n' "$tasker_foreground"

printf '\nTASKER INTEGRATION\n'
printf '  Notification access:  %s\n' "$tasker_notification_access"
printf '  Accessibility:        %s\n' "$tasker_accessibility"

printf '\n'
