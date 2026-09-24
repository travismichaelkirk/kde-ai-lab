/*
 * KDE AI Lab - AI + Terminal Layout Prototype
 *
 * Finds the ChatGPT PWA and Konsole by desktop-file identity,
 * then uses KWin's native quick-tile operations to create
 * the verified 50/50 workspace.
 */

const CHATGPT_DESKTOP_FILE =
    "chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default";

const KONSOLE_DESKTOP_FILE =
    "org.kde.konsole";

function log(message) {
    console.info("kde-ai-lab-layout: " + message);
}

function findWindow(desktopFileName) {
    return workspace.windowList().find((window) =>
        window.normalWindow &&
        window.desktopFileName === desktopFileName
    );
}

function main() {
    const chatgpt = findWindow(CHATGPT_DESKTOP_FILE);
    const konsole = findWindow(KONSOLE_DESKTOP_FILE);

    if (!chatgpt) {
        log("ChatGPT window not found; no changes made.");
        return;
    }

    if (!konsole) {
        log("Konsole window not found; no changes made.");
        return;
    }

    log("ChatGPT and Konsole found.");

    workspace.activeWindow = chatgpt;
    workspace.slotWindowQuickTileLeft();

    workspace.activeWindow = konsole;
    workspace.slotWindowQuickTileRight();

    log("AI + Terminal layout requested.");
}

main();
