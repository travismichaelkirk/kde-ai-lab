#!/usr/bin/env bash

set -euo pipefail

CHROME="/usr/bin/google-chrome"
PROFILE_DIR="$HOME/.local/share/kde-ai-lab/aux-browser"

log() {
    printf 'kde-ai-lab-aux: %s\n' "$*"
}

fail() {
    printf 'kde-ai-lab-aux: ERROR: %s\n' "$*" >&2
    exit 1
}

[[ -x "$CHROME" ]] ||
    fail "Google Chrome executable not found: $CHROME"

mkdir -p "$PROFILE_DIR"

log "profile: $PROFILE_DIR"
log "starting AUX browser"

exec "$CHROME" \
    --user-data-dir="$PROFILE_DIR" \
    --class=kde-ai-lab-aux \
    --no-first-run \
    --no-default-browser-check \
    --new-window \
    about:blank
