#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

KWIN_PLUGIN="kde-ai-lab-workspace"

KONSOLE_PROFILE_SOURCE="$PROJECT_ROOT/konsole/KDE-AI-Lab.profile"
KONSOLE_PROFILE_DIR="$HOME/.local/share/konsole"
KONSOLE_PROFILE_TARGET="$KONSOLE_PROFILE_DIR/KDE-AI-Lab.profile"

KONSOLE_DESKTOP_SOURCE="$PROJECT_ROOT/desktop/kde-ai-lab-konsole.desktop"
KONSOLE_DESKTOP_DIR="$HOME/.local/share/applications"
KONSOLE_DESKTOP_TARGET="$KONSOLE_DESKTOP_DIR/kde-ai-lab-konsole.desktop"

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

verify_konsole_assets() {
    if ! cmp -s "$KONSOLE_PROFILE_SOURCE" "$KONSOLE_PROFILE_TARGET"; then
        log "ERROR: KDE AI Lab Konsole profile is not installed"
        log "Run scripts/install-kde-ai-workspace.sh"
        return 1
    fi

    if ! cmp -s "$KONSOLE_DESKTOP_SOURCE" "$KONSOLE_DESKTOP_TARGET"; then
        log "ERROR: KDE AI Lab desktop entry is not installed"
        log "Run scripts/install-kde-ai-workspace.sh"
        return 1
    fi

    log "KDE AI Lab Konsole assets are installed"
}

ensure_konsole() {
    if pgrep -f '/usr/bin/konsole.*--desktopfile kde-ai-lab-konsole' >/dev/null; then
        log "KDE AI Lab Konsole already running"
        return
    fi

    log "KDE AI Lab Konsole not running; launching"

    /usr/bin/konsole \
        --separate \
        --desktopfile kde-ai-lab-konsole \
        --profile KDE-AI-Lab \
        --workdir "$PROJECT_ROOT" \
        >/dev/null 2>&1 &
}

ensure_android_screen() {
    if pgrep -f '/scrcpy .*adb-' >/dev/null; then
        log "Android screen already running"
        return
    fi

    log "Android screen not running; launching"

    "$SCRIPT_DIR/android-screen.sh" \
        >/tmp/kde-ai-lab-android.log 2>&1 &
}

ensure_aux_browser() {
    if pgrep -f 'chrome.*kde-ai-lab-aux' >/dev/null; then
        log "AUX browser already running"
        return
    fi

    log "AUX browser not running; launching"

    "$SCRIPT_DIR/aux-browser.sh" \
        >/tmp/kde-ai-lab-aux-launcher.log 2>&1 &
}

main() {
    log "launcher started"
    verify_konsole_assets
    verify_kwin_controller
    ensure_konsole
    ensure_android_screen
    ensure_aux_browser
}

main "$@"
