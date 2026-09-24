/*
 * KDE AI Lab - AI + Terminal Workspace
 *
 * Waits for the ChatGPT PWA and Konsole to exist, moves both
 * to the primary output, then creates an idempotent 50/50
 * ChatGPT-left / Konsole-right workspace.
 */

const CHATGPT_DESKTOP_FILE =
    "chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default";

const KONSOLE_DESKTOP_FILE =
    "org.kde.konsole";

let chatgptLaunchRequested = false;

function log(message) {
    console.info("kde-ai-lab-workspace: " + message);
}

function requestChatGPTLaunch() {
    if (chatgptLaunchRequested) {
        log("ChatGPT launch already requested; waiting for window.");
        return;
    }

    chatgptLaunchRequested = true;
    log("ChatGPT missing; requesting kde-ai-chatgpt.service.");

    callDBus(
        "org.freedesktop.systemd1",
        "/org/freedesktop/systemd1",
        "org.freedesktop.systemd1.Manager",
        "StartUnit",
        "kde-ai-chatgpt.service",
        "replace",
        function(job) {
            log("ChatGPT launch request accepted: " + job);
        }
    );
}

function findWindow(desktopFileName) {
    return workspace.windowList().find((window) =>
        window.normalWindow &&
        window.desktopFileName === desktopFileName
    );
}

function isLeftHalf(window, output) {
    const g = window.frameGeometry;
    const o = output.geometry;

    return (
        g.x === o.x &&
        g.width === o.width / 2
    );
}

function isRightHalf(window, output) {
    const g = window.frameGeometry;
    const o = output.geometry;

    return (
        g.x === o.x + o.width / 2 &&
        g.width === o.width / 2
    );
}

function arrangeWorkspace() {
    const chatgpt = findWindow(CHATGPT_DESKTOP_FILE);
    const konsole = findWindow(KONSOLE_DESKTOP_FILE);

    if (chatgpt) {
        chatgptLaunchRequested = false;
    }

    if (!chatgpt || !konsole) {
        log(
            "waiting: ChatGPT=" + (chatgpt ? "found" : "missing") +
            ", Konsole=" + (konsole ? "found" : "missing")
        );

        if (!chatgpt) {
            requestChatGPTLaunch();
        }

        return;
    }

    const targetOutput = workspace.screenOrder[0];

    log(
        "ChatGPT and Konsole found; arranging workspace on " +
        targetOutput.name + "."
    );

    workspace.sendClientToScreen(chatgpt, targetOutput);
    workspace.sendClientToScreen(konsole, targetOutput);

    if (!isLeftHalf(chatgpt, targetOutput)) {
        log("ChatGPT is not left-half; requesting QuickTileLeft.");
        workspace.activeWindow = chatgpt;
        workspace.slotWindowQuickTileLeft();
    } else {
        log("ChatGPT already left-half.");
    }

    if (!isRightHalf(konsole, targetOutput)) {
        log("Konsole is not right-half; requesting QuickTileRight.");
        workspace.activeWindow = konsole;
        workspace.slotWindowQuickTileRight();
    } else {
        log("Konsole already right-half.");
    }

    log("AI + Terminal workspace complete.");
}

function scheduleWorkspaceCheck() {
    const timer = new QTimer();
    timer.interval = 250;
    timer.singleShot = true;

    timer.timeout.connect(() => {
        arrangeWorkspace();
    });

    timer.start();
}

function main() {
    workspace.windowAdded.connect(() => {
        scheduleWorkspaceCheck();
    });

    workspace.windowRemoved.connect(() => {
        scheduleWorkspaceCheck();
    });

    arrangeWorkspace();
}

main();
