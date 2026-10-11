#!/usr/bin/env bash

set -euo pipefail

echo "=================================="
echo " KDE AI Lab - Android Diagnostics"
echo "=================================="

if ! command -v adb >/dev/null 2>&1; then
    echo "ERROR: ADB is not installed."
    exit 1
fi

echo
echo "ADB Version:"
adb version | head -n 2

echo
echo "Connected Devices:"
adb devices -l

echo
device_count=$(adb devices | awk '$2 == "device" {count++} END {print count+0}')

if [[ "$device_count" -ne 1 ]]; then
    echo "ERROR: Expected exactly one authorized Android device."
    exit 1
fi

echo "Device Information:"
echo "Model: $(adb shell getprop ro.product.model | tr -d '\r')"
echo "Android: $(adb shell getprop ro.build.version.release | tr -d '\r')"
echo "API Level: $(adb shell getprop ro.build.version.sdk | tr -d '\r')"
echo "ADB Enabled: $(adb shell settings get global adb_enabled | tr -d '\r')"

echo
echo "Diagnostics completed successfully."
