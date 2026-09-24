/*
 * KDE AI Lab - KWin Window Diagnostics
 *
 * Temporary discovery script.
 * Enumerates normal windows and reports identifying properties.
 * It does not move, resize, activate, close, or modify windows.
 */

function log(message) {
    console.info("kde-ai-lab-window-diagnostics: " + message);
}

function valueOrUnknown(value) {
    if (value === undefined) {
        return "<undefined>";
    }

    if (value === null) {
        return "<null>";
    }

    return String(value);
}

function inspectWindow(window) {
    if (!window.normalWindow) {
        return;
    }

    log(
        "caption=" + valueOrUnknown(window.caption) +
        " | resourceName=" + valueOrUnknown(window.resourceName) +
        " | resourceClass=" + valueOrUnknown(window.resourceClass) +
        " | desktopFileName=" + valueOrUnknown(window.desktopFileName)
    );
}

function main() {
    const windows = workspace.windowList();

    log("normal-window diagnostic started; total windows=" + windows.length);

    windows.forEach((window) => {
        inspectWindow(window);
    });

    log("diagnostic complete");
}

main();
