#!/usr/bin/env bash
set -euo pipefail

echo "=================================="
echo " KDE AI Lab - Tasker Log Monitor"
echo "=================================="

if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: ADB is not installed."
    exit 1
fi

device_count=$(adb devices | awk '$2 == "device" {count++} END {print count+0}')

if [[ "$device_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly one authorized Android device."
    exit 1
fi

if ! adb shell pm list packages --user 0 net.dinglisch.android.taskerm \
    | grep -qx 'package:net.dinglisch.android.taskerm'; then
    echo "ERROR: Tasker not found in Android user 0."
    exit 1
fi

mode="${1:-}"

if [[ -n "$mode" && "$mode" != "--warnings" ]]; then
    echo "Usage: $0 [--warnings]"
    exit 2
fi

echo
echo "Monitoring Tasker-related Android logs..."
echo "Press Ctrl+C to stop."
echo

if [[ "$mode" == "--warnings" ]]; then
    echo "Mode: Tasker warnings and errors only"
    adb logcat -T 1 -v threadtime 'Tasker:W' '*:S'
else
    echo "Mode: Tasker-related activity (INFO and above)"
    adb logcat -T 1 -v threadtime '*:I' \
        | grep --line-buffered -i -E 'tasker|net\.dinglisch'
fi
