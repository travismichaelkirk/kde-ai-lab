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

const AUX_DESKTOP_FILE =
    "kde-ai-lab-aux";

let chatgptLaunchRequested = false;
let pixelCenterTimer;
let auxSettleTimer;

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
    const aux = findWindow(AUX_DESKTOP_FILE);

    log(
        "multi-output mode: ChatGPT -> " +
        leftOutput.name +
        ", Konsole -> left half of " +
        rightOutput.name +
        (pixel ? ", Pixel -> middle lane" : "") +
        (aux ? ", AUX -> right lane." : ".")
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

    const pixelRight =
        pixel.frameGeometry.x + pixel.frameGeometry.width;

    log(
        "Pixel left-anchored at x=" + pixelLaneX +
        "; width=" + pixel.frameGeometry.width +
        "; AUX lane begins at x=" + pixelRight + "."
    );

    if (!aux) {
        log("AUX not present; right lane remains available.");
        return;
    }

    workspace.sendClientToScreen(aux, rightOutput);

    if (aux.maximizeMode !== 0) {
        log("Restoring AUX before positioning.");
        aux.setMaximize(false, false);
    }

    const outputRight =
        rightGeometry.x + rightGeometry.width;

    aux.frameGeometry = {
        x: pixelRight,
        y: rightGeometry.y,
        width: outputRight - pixelRight,
        height: rightGeometry.height
    };

    log(
        "AUX positioned at x=" + aux.frameGeometry.x +
        "; width=" + aux.frameGeometry.width +
        "; right edge=" +
        (aux.frameGeometry.x + aux.frameGeometry.width) + "."
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

    if (
        outputs.length > 1 &&
        findWindow(SCRCPY_DESKTOP_FILE)
    ) {
        pixelCenterTimer.start();
    }

    if (
        outputs.length > 1 &&
        findWindow(SCRCPY_DESKTOP_FILE) &&
        findWindow(AUX_DESKTOP_FILE)
    ) {
        auxSettleTimer.start();
    }

    log("AI + Terminal workspace complete.");
}

const workspaceCheckTimer = new QTimer();
workspaceCheckTimer.interval = 250;
workspaceCheckTimer.singleShot = true;

workspaceCheckTimer.timeout.connect(() => {
    arrangeWorkspace();
});

pixelCenterTimer = new QTimer();
pixelCenterTimer.interval = 500;
pixelCenterTimer.singleShot = true;

pixelCenterTimer.timeout.connect(() => {
    const pixel = findWindow(SCRCPY_DESKTOP_FILE);
    const outputs = getOutputsLeftToRight();

    if (!pixel || outputs.length < 2) {
        return;
    }

    const rightOutput = outputs[outputs.length - 1];
    const placementArea = workspace.clientArea(
        KWin.PlacementArea,
        rightOutput,
        workspace.currentDesktop
    );
    const pixelGeometry = pixel.frameGeometry;

    const centeredY =
        placementArea.y +
        Math.floor(
            (placementArea.height - pixelGeometry.height) / 2
        );

    pixel.frameGeometry = {
        x: pixelGeometry.x,
        y: centeredY,
        width: pixelGeometry.width,
        height: pixelGeometry.height
    };

    log(
        "Pixel vertically centered at y=" + centeredY +
        "; settled height=" + pixelGeometry.height + "."
    );
});

auxSettleTimer = new QTimer();
auxSettleTimer.interval = 500;
auxSettleTimer.singleShot = true;

auxSettleTimer.timeout.connect(() => {
    const pixel = findWindow(SCRCPY_DESKTOP_FILE);
    const aux = findWindow(AUX_DESKTOP_FILE);
    const outputs = getOutputsLeftToRight();

    if (!pixel || !aux || outputs.length < 2) {
        return;
    }

    const rightOutput = outputs[outputs.length - 1];
    const rightGeometry = rightOutput.geometry;

    workspace.sendClientToScreen(aux, rightOutput);

    if (aux.maximizeMode !== 0) {
        aux.setMaximize(false, false);
    }

    const pixelGeometry = pixel.frameGeometry;
    const pixelRight =
        pixelGeometry.x + pixelGeometry.width;
    const outputRight =
        rightGeometry.x + rightGeometry.width;

    aux.frameGeometry = {
        x: pixelRight,
        y: rightGeometry.y,
        width: outputRight - pixelRight,
        height: rightGeometry.height
    };

    log(
        "AUX settled at x=" + aux.frameGeometry.x +
        "; width=" + aux.frameGeometry.width +
        "; right edge=" +
        (aux.frameGeometry.x + aux.frameGeometry.width) + "."
    );
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
