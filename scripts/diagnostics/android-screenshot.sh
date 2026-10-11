#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
capture_dir="$repo_dir/captures"

echo "=================================="
echo " KDE AI Lab - Android Screenshot"
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

mkdir -p -m 700 "$capture_dir"

timestamp="$(date +%Y%m%d-%H%M%S)"
screenshot="$capture_dir/android-$timestamp.png"

if [[ -e "$screenshot" ]]; then
    echo "ERROR: Screenshot filename already exists."
    exit 1
fi

echo
echo "Capturing Android screen..."

if ! adb exec-out screencap -p > "$screenshot"; then
    rm -f -- "$screenshot"
    echo "ERROR: Screenshot capture failed."
    exit 1
fi

if [[ ! -s "$screenshot" ]]; then
    rm -f -- "$screenshot"
    echo "ERROR: Screenshot is empty."
    exit 1
fi

chmod 600 "$screenshot"

echo "Screenshot saved:"
echo "$screenshot"
