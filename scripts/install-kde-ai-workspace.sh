#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

KWIN_PLUGIN="kde-ai-lab-workspace"
KWIN_PACKAGE="$PROJECT_ROOT/scripts/kwin/packages/$KWIN_PLUGIN"

SYSTEMD_UNIT="kde-ai-chatgpt.service"
SYSTEMD_SOURCE="$PROJECT_ROOT/systemd/user/$SYSTEMD_UNIT"
SYSTEMD_TARGET="$HOME/.config/systemd/user/$SYSTEMD_UNIT"

log() {
    printf 'kde-ai-lab-install: %s\n' "$*"
}

fail() {
    printf 'kde-ai-lab-install: ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 ||
        fail "required command not found: $1"
}

verify_requirements() {
    log "checking requirements"

    require_command kpackagetool6
    require_command kwriteconfig6
    require_command qdbus-qt6
    require_command systemctl

    [[ -f "$KWIN_PACKAGE/metadata.json" ]] ||
        fail "KWin package metadata not found"

    [[ -f "$KWIN_PACKAGE/contents/code/main.js" ]] ||
        fail "KWin package main.js not found"

    [[ -f "$SYSTEMD_SOURCE" ]] ||
        fail "systemd user unit not found"
}

install_kwin_package() {
    log "installing KWin package"

    if kpackagetool6 \
        --type=KWin/Script \
        --list 2>/dev/null |
        grep -Fxq "$KWIN_PLUGIN"; then

        log "existing KWin package found; upgrading"

        kpackagetool6 \
            --type=KWin/Script \
            --upgrade "$KWIN_PACKAGE"
    else
        log "KWin package not installed; installing"

        kpackagetool6 \
            --type=KWin/Script \
            --install "$KWIN_PACKAGE"
    fi
}

install_systemd_unit() {
    log "installing systemd user unit"

    mkdir -p "$HOME/.config/systemd/user"

    install -m 0644 \
        "$SYSTEMD_SOURCE" \
        "$SYSTEMD_TARGET"

    systemctl --user daemon-reload
}

enable_kwin_plugin() {
    log "enabling KWin plugin"

    kwriteconfig6 \
        --file kwinrc \
        --group Plugins \
        --key "${KWIN_PLUGIN}Enabled" \
        true
}

reconfigure_kwin() {
    log "requesting KWin reconfigure"

    qdbus-qt6 org.kde.KWin /KWin \
        org.kde.KWin.reconfigure
}

verify_installation() {
    log "verifying installation"

    sleep 1

    local loaded

    loaded="$(
        qdbus-qt6 org.kde.KWin /Scripting \
            org.kde.kwin.Scripting.isScriptLoaded \
            "$KWIN_PLUGIN"
    )"

    if [[ "$loaded" != "true" ]]; then
        fail "KWin workspace controller is not loaded"
    fi

    if [[ ! -f "$SYSTEMD_TARGET" ]]; then
        fail "systemd user unit was not installed"
    fi

    log "KWin workspace controller is loaded"
    log "systemd user unit is installed"
}

main() {
    log "installation started"

    verify_requirements
    install_kwin_package
    install_systemd_unit
    enable_kwin_plugin
    reconfigure_kwin
    verify_installation

    log "installation complete"
}

main "$@"
