/*
 * KDE AI Lab - AI + Terminal Workspace
 *
 * Waits for the ChatGPT PWA and Konsole to exist and creates
 * a topology-aware workspace:
 *
 *   2+ outputs:
 *     ChatGPT -> leftmost output, maximized
 *     Konsole -> rightmost output, maximized
 *
 *   1 output:
 *     ChatGPT -> left half
 *     Konsole -> right half
 */

const CHATGPT_DESKTOP_FILE =
    "chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default";

const KONSOLE_DESKTOP_FILE =
    "org.kde.konsole";

const SCRCPY_DESKTOP_FILE =
    "scrcpy";

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

function getOutputsLeftToRight() {
    return workspace.screens.slice().sort((a, b) =>
        a.geometry.x - b.geometry.x
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

function arrangeSingleOutput(chatgpt, konsole, output) {
    log(
        "single-output mode on " + output.name +
        "; arranging 50/50 workspace."
    );

    workspace.sendClientToScreen(chatgpt, output);
    workspace.sendClientToScreen(konsole, output);

    /*
     * A window may arrive here maximized after previously being used
     * in dual-output mode. Restore it before applying quick tiling.
     */
    if (chatgpt.maximizeMode !== 0) {
        log("Restoring ChatGPT from maximized state.");
        chatgpt.setMaximize(false, false);
    }

    if (konsole.maximizeMode !== 0) {
        log("Restoring Konsole from maximized state.");
        konsole.setMaximize(false, false);
    }

    if (!isLeftHalf(chatgpt, output)) {
        log("ChatGPT is not left-half; requesting QuickTileLeft.");
        workspace.activeWindow = chatgpt;
        workspace.slotWindowQuickTileLeft();
    } else {
        log("ChatGPT already left-half.");
    }

    if (!isRightHalf(konsole, output)) {
        log("Konsole is not right-half; requesting QuickTileRight.");
        workspace.activeWindow = konsole;
        workspace.slotWindowQuickTileRight();
    } else {
        log("Konsole already right-half.");
    }
}

function arrangeDualOutput(chatgpt, konsole, outputs) {
    const leftOutput = outputs[0];
    const rightOutput = outputs[outputs.length - 1];
    const pixel = findWindow(SCRCPY_DESKTOP_FILE);

    log(
        "multi-output mode: ChatGPT -> " +
        leftOutput.name +
        ", Konsole -> left half of " +
        rightOutput.name +
        (pixel ? ", Pixel -> middle quarter." : ".")
    );

    workspace.sendClientToScreen(chatgpt, leftOutput);
    workspace.sendClientToScreen(konsole, rightOutput);

    if (chatgpt.maximizeMode !== 3) {
        log("Maximizing ChatGPT on " + leftOutput.name + ".");
        chatgpt.setMaximize(true, true);
    } else {
        log("ChatGPT already maximized on " + leftOutput.name + ".");
    }

    if (konsole.maximizeMode !== 0) {
        log("Restoring Konsole before positioning.");
        konsole.setMaximize(false, false);
    }

    const rightGeometry = rightOutput.geometry;

    konsole.frameGeometry = {
        x: rightGeometry.x,
        y: rightGeometry.y,
        width: rightGeometry.width / 2,
        height: rightGeometry.height
    };

    if (!pixel) {
        log("Pixel not present; Pixel lane remains available.");
        return;
    }

    workspace.sendClientToScreen(pixel, rightOutput);

    if (pixel.maximizeMode !== 0) {
        log("Restoring Pixel before positioning.");
        pixel.setMaximize(false, false);
    }

    const pixelGeometry = pixel.frameGeometry;
    const pixelLaneX =
        rightGeometry.x + rightGeometry.width / 2;

    pixel.frameGeometry = {
        x: pixelLaneX,
        y: rightGeometry.y,
        width: pixelGeometry.width,
        height: rightGeometry.height
    };

    log(
        "Pixel left-anchored at x=" + pixelLaneX +
        "; width=" + pixel.frameGeometry.width +
        "; AUX lane reserved on right."
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

    const outputs = getOutputsLeftToRight();

    if (outputs.length === 0) {
        log("No outputs available; workspace arrangement skipped.");
        return;
    }

    if (outputs.length === 1) {
        arrangeSingleOutput(chatgpt, konsole, outputs[0]);
    } else {
        arrangeDualOutput(chatgpt, konsole, outputs);
    }

    log("AI + Terminal workspace complete.");
}

const workspaceCheckTimer = new QTimer();
workspaceCheckTimer.interval = 250;
workspaceCheckTimer.singleShot = true;

workspaceCheckTimer.timeout.connect(() => {
    arrangeWorkspace();
});

function scheduleWorkspaceCheck() {
    workspaceCheckTimer.start();
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
