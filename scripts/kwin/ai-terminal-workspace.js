/*
 * KDE AI Lab - AI + Terminal Workspace
 *
 * Waits for the ChatGPT PWA and Konsole to exist, then uses
 * KWin's native quick-tile operations to create the verified
 * 50/50 workspace.
 */

const CHATGPT_DESKTOP_FILE =
    "chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default";

const KONSOLE_DESKTOP_FILE =
    "org.kde.konsole";

let layoutComplete = false;

function log(message) {
    console.info("kde-ai-lab-workspace: " + message);
}

function findWindow(desktopFileName) {
    return workspace.windowList().find((window) =>
        window.normalWindow &&
        window.desktopFileName === desktopFileName
    );
}

function arrangeWorkspace() {
    if (layoutComplete) {
        return;
    }

    const chatgpt = findWindow(CHATGPT_DESKTOP_FILE);
    const konsole = findWindow(KONSOLE_DESKTOP_FILE);

    if (!chatgpt || !konsole) {
        log(
            "waiting: ChatGPT=" + (chatgpt ? "found" : "missing") +
            ", Konsole=" + (konsole ? "found" : "missing")
        );
        return;
    }

    log("ChatGPT and Konsole found; arranging workspace.");

    workspace.activeWindow = chatgpt;
    workspace.slotWindowQuickTileLeft();

    workspace.activeWindow = konsole;
    workspace.slotWindowQuickTileRight();

    layoutComplete = true;
    log("AI + Terminal workspace complete.");
}

function main() {
    workspace.windowAdded.connect(() => {
        arrangeWorkspace();
    });

    arrangeWorkspace();
}

main();
