#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

KWIN_SCRIPT="$PROJECT_ROOT/scripts/kwin/ai-terminal-workspace.js"
KWIN_PLUGIN="kde-ai-lab-workspace"

log() {
    printf 'kde-ai-lab-launcher: %s\n' "$*"
}

kwin_script_loaded() {
    qdbus-qt6 org.kde.KWin /Scripting \
        org.kde.kwin.Scripting.isScriptLoaded \
        "$KWIN_PLUGIN"
}

start_kwin_controller() {
    if [[ "$(kwin_script_loaded)" == "true" ]]; then
        log "unloading existing KWin workspace controller"

        qdbus-qt6 org.kde.KWin /Scripting \
            org.kde.kwin.Scripting.unloadScript \
            "$KWIN_PLUGIN"

        if [[ "$(kwin_script_loaded)" == "true" ]]; then
            log "ERROR: KWin workspace controller failed to unload"
            return 1
        fi
    fi

    log "loading KWin workspace controller"

    qdbus-qt6 org.kde.KWin /Scripting \
        org.kde.kwin.Scripting.loadScript \
        "$KWIN_SCRIPT" \
        "$KWIN_PLUGIN"

    if [[ "$(kwin_script_loaded)" != "true" ]]; then
        log "ERROR: KWin workspace controller failed to load"
        return 1
    fi

    log "starting KWin workspace controller"

    qdbus-qt6 org.kde.KWin /Scripting \
        org.kde.kwin.Scripting.start
}

ensure_konsole() {
    if pgrep -x konsole >/dev/null; then
        log "Konsole already running"
        return
    fi

    log "Konsole not running; launching"
    /usr/bin/konsole >/dev/null 2>&1 &
}

main() {
    log "launcher started"
    start_kwin_controller
    ensure_konsole
}

main "$@"
