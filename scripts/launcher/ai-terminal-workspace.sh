#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

KWIN_PLUGIN="kde-ai-lab-workspace"

KONSOLE_PROFILE_SOURCE="$PROJECT_ROOT/konsole/KDE-AI-Lab.profile"
KONSOLE_PROFILE_DIR="$HOME/.local/share/konsole"
KONSOLE_PROFILE_TARGET="$KONSOLE_PROFILE_DIR/KDE-AI-Lab.profile"

log() {
    printf 'kde-ai-lab-launcher: %s\n' "$*"
}

kwin_script_loaded() {
    qdbus-qt6 org.kde.KWin /Scripting \
        org.kde.kwin.Scripting.isScriptLoaded \
        "$KWIN_PLUGIN"
}

verify_kwin_controller() {
    if [[ "$(kwin_script_loaded)" != "true" ]]; then
        log "ERROR: installed KWin workspace controller is not loaded"
        log "Run scripts/install-kde-ai-workspace.sh to install the workspace controller"
        return 1
    fi

    log "installed KWin workspace controller is loaded"
}

ensure_konsole_profile() {
    if [[ ! -f "$KONSOLE_PROFILE_SOURCE" ]]; then
        log "ERROR: Konsole profile source not found: $KONSOLE_PROFILE_SOURCE"
        return 1
    fi

    mkdir -p "$KONSOLE_PROFILE_DIR"

    if [[ -f "$KONSOLE_PROFILE_TARGET" ]] &&
        cmp -s "$KONSOLE_PROFILE_SOURCE" "$KONSOLE_PROFILE_TARGET"
    then
        log "KDE AI Lab Konsole profile already installed"
        return
    fi

    log "installing KDE AI Lab Konsole profile"
    cp "$KONSOLE_PROFILE_SOURCE" "$KONSOLE_PROFILE_TARGET"
}

ensure_konsole() {
    if pgrep -x konsole >/dev/null; then
        log "Konsole already running"
        return
    fi

    log "Konsole not running; launching KDE AI Lab profile"
    /usr/bin/konsole \
        --profile KDE-AI-Lab \
        --workdir "$PROJECT_ROOT" \
        >/dev/null 2>&1 &
}

main() {
    log "launcher started"
    ensure_konsole_profile
    verify_kwin_controller
    ensure_konsole
}

main "$@"
