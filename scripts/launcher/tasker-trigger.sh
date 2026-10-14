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

[[ $# -eq 1 ]] ||
    fail "usage: $(basename "$0") <command>"

command_name="$1"

[[ "$command_name" =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    fail "command must contain only lowercase letters, numbers, and hyphens"

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
log "Tasker command: $command_name"
token_file="$HOME/.config/kde-ai-lab/token"

[[ -f "$token_file" && -r "$token_file" ]] ||
    fail "Tasker authentication token file is missing or unreadable"

token="$(< "$token_file")"

[[ "$token" =~ ^[[:xdigit:]]{64}$ ]] ||
    fail "Tasker authentication token has an invalid format"

log "triggering authenticated Tasker HTTP bridge"

# Supply the authentication header through curl configuration on stdin,
# rather than exposing the token in process command-line arguments.
printf 'header = "X-KDE-AI-Lab-Token: %s"\n' "$token" |
    curl \
        --config - \
        --silent \
        --show-error \
        --fail \
        --connect-timeout 5 \
        --max-time 15 \
        "http://${pixel_ip}:8765/${command_name}" ||
    fail "Tasker HTTP request failed or bridge is unavailable"

log "Tasker HTTP request completed successfully"
