#!/usr/bin/env bash
set -euo pipefail

# KDE AI Lab v0.8 — Wireless ADB Connection Manager
# Phase 1: Discovery and connection detection only.

PIXEL_SERIAL="67140DLKX00137"
SERVICE_TYPE="_adb-tls-connect._tcp"

echo "KDE AI Lab — Wireless ADB Connection Manager"
echo "Searching for Pixel serial: $PIXEL_SERIAL"

if ! command -v avahi-browse >/dev/null 2>&1; then
    echo "ERROR: avahi-browse is not installed." >&2
    exit 1
fi

# Collect all discovery records before parsing them.
# This avoids SIGPIPE when selecting the first matching endpoint.
if discovery="$(timeout 8 avahi-browse -rtp "$SERVICE_TYPE")"; then
    :
else
    status=$?
    if [[ "$status" -eq 124 ]]; then
        echo "ERROR: Avahi discovery timed out." >&2
    else
        echo "ERROR: Avahi discovery failed (exit code $status)." >&2
    fi
    exit 1
fi

endpoint="$(
    printf '%s\n' "$discovery" |
    awk -F ';' -v serial="$PIXEL_SERIAL" '
        $1 == "=" && $3 == "IPv4" &&
        index($4, "adb-" serial "-") == 1 &&
        !found {
            print $8 ":" $9
            found = 1
        }
    '
)"

if [[ -z "$endpoint" ]]; then
    echo "ERROR: Pixel TLS service not discovered." >&2
    exit 1
fi

echo "Discovered endpoint: $endpoint"
echo
echo "Checking existing ADB connections..."

connected=false
adb_list="$(timeout 10 adb devices)" || {
    echo "ERROR: Unable to list ADB connections." >&2
    exit 1
}

while read -r transport state _; do
    [[ "$state" == "device" ]] || continue

    if [[ "$transport" == "$endpoint" ]] ||
       [[ "$transport" == adb-"$PIXEL_SERIAL"-*._adb-tls-connect._tcp ]]; then

        actual_serial="$(timeout 5 adb -s "$transport" shell getprop ro.serialno 2>/dev/null)" || actual_serial=""

        if [[ "$actual_serial" == "$PIXEL_SERIAL" ]]; then
            echo "Verified active connection: $transport"
            connected=true
            break
        fi

        echo "Connection not responding or identity mismatch: $transport"
    fi
done <<< "$adb_list"

if [[ "$connected" == false ]]; then
    echo "No verified active connection found."
fi

echo
echo "Evaluating connection recovery..."

if [[ "$connected" == true ]]; then
    echo "Pixel already connected and verified. No recovery needed."
else
    echo "Pixel connection unavailable. Attempting recovery..."
    if timeout 10 adb connect "$endpoint"; then
        echo "Verifying recovered ADB connection..."

        actual_serial="$(timeout 10 adb -s "$endpoint" shell getprop ro.serialno 2>/dev/null)" || {
            echo "ERROR: Recovered ADB connection is not responding." >&2
            exit 1
        }

        if [[ "$actual_serial" != "$PIXEL_SERIAL" ]]; then
            echo "ERROR: Connected device identity does not match expected Pixel." >&2
            exit 1
        fi

        echo "Recovery successful. Pixel authenticated and responding."
    else
        echo "ERROR: ADB connection attempt failed." >&2
        exit 1
    fi
fi
