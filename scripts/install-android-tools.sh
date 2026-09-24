#!/usr/bin/env bash

set -euo pipefail

SCRCPY_VERSION="4.1"
SCRCPY_ARCHIVE="scrcpy-linux-x86_64-v${SCRCPY_VERSION}.tar.gz"
SCRCPY_DIRECTORY="scrcpy-linux-x86_64-v${SCRCPY_VERSION}"
SCRCPY_URL="https://github.com/Genymobile/scrcpy/releases/download/v${SCRCPY_VERSION}/${SCRCPY_ARCHIVE}"
SCRCPY_SHA256="ad56ae8bfeedf41e824945c11dbf55fcb092b3e615b9b486f48a50e30d389635"

INSTALL_ROOT="$HOME/.local/lib/kde-ai-lab"
INSTALL_DIR="$INSTALL_ROOT/scrcpy-${SCRCPY_VERSION}"

log() {
    printf 'kde-ai-lab-android-install: %s\n' "$*"
}

fail() {
    printf 'kde-ai-lab-android-install: ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        fail "required command not found: $1"
}

verify_host() {
    log "checking host"

    if [[ "$(uname -m)" != "x86_64" ]]; then
        fail "scrcpy binary package currently supports x86_64 hosts only"
    fi

    if ! command -v adb >/dev/null 2>&1; then
        fail "adb is not installed; on Fedora install it with: sudo dnf install android-tools"
    fi

    require_command curl
    require_command sha256sum
    require_command tar
    require_command mktemp

    log "ADB: $(command -v adb)"
}

verify_existing_installation() {
    if [[ ! -x "$INSTALL_DIR/scrcpy" ]]; then
        return 1
    fi

    local version

    version="$("$INSTALL_DIR/scrcpy" --version | head -1)"

    if [[ "$version" == "scrcpy ${SCRCPY_VERSION} "* ]]; then
        log "scrcpy ${SCRCPY_VERSION} is already installed"
        return 0
    fi

    return 1
}

install_scrcpy() {
    local work_dir
    local archive
    local extracted

    work_dir="$(mktemp -d)"

    archive="$work_dir/$SCRCPY_ARCHIVE"
    extracted="$work_dir/$SCRCPY_DIRECTORY"

    log "downloading scrcpy ${SCRCPY_VERSION}"

    curl -fL \
        "$SCRCPY_URL" \
        -o "$archive"

    log "verifying archive checksum"

    printf '%s  %s\n' \
        "$SCRCPY_SHA256" \
        "$archive" |
        sha256sum --check --status ||
        fail "scrcpy archive checksum verification failed"

    log "extracting scrcpy"

    tar -xzf "$archive" -C "$work_dir"

    [[ -x "$extracted/scrcpy" ]] ||
        fail "scrcpy executable missing from extracted archive"

    [[ -f "$extracted/scrcpy-server" ]] ||
        fail "scrcpy server missing from extracted archive"

    mkdir -p "$INSTALL_ROOT"

    rm -rf "$INSTALL_DIR"
    mv "$extracted" "$INSTALL_DIR"

    log "installed scrcpy to $INSTALL_DIR"

    rm -rf "$work_dir"
}

verify_installation() {
    log "verifying installation"

    [[ -x "$INSTALL_DIR/scrcpy" ]] ||
        fail "installed scrcpy executable not found"

    [[ -f "$INSTALL_DIR/scrcpy-server" ]] ||
        fail "installed scrcpy server not found"

    "$INSTALL_DIR/scrcpy" --version | head -2

    log "installation verified"
}

main() {
    log "installation started"

    verify_host

    if ! verify_existing_installation; then
        install_scrcpy
    fi

    verify_installation

    log "installation complete"
}

main "$@"
