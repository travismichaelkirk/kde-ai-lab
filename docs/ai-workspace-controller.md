# AI Workspace Controller

## Purpose

The KDE AI Lab workspace controller creates and maintains a predictable
ChatGPT + Konsole workspace while adapting automatically to the current
display topology.

The controller is implemented as a persistent KWin script and is designed
to remove repetitive window-management work without requiring hard-coded
screen coordinates.

## Current Platform

Initial implementation and verification:

- Fedora KDE Plasma
- Plasma 6.7.4
- KWin 6.7.4
- Wayland
- Google Chrome ChatGPT PWA
- Konsole

## Workspace Behavior

### Two or More Outputs

When multiple outputs are available:

- ChatGPT is placed on the leftmost output.
- Konsole is placed on the rightmost output.
- ChatGPT is maximized.
- Konsole is maximized.

The controller determines left and right from the current output geometry
rather than relying on fixed output names such as `DP-1` or `DP-2`.

### Single Output

When one output is available:

- ChatGPT is placed on the left half.
- Konsole is placed on the right half.

If either application was previously maximized in a multi-output layout,
the controller restores it before applying the 50/50 layout.

## Dynamic Topology Changes

The workspace automatically adapts when the display topology changes.

Verified transitions include:

- Two outputs to one output:
  ChatGPT and Konsole move to the remaining display and become a 50/50 layout.
- One output to two outputs:
  ChatGPT moves to the leftmost display and maximizes.
  Konsole moves to the rightmost display and maximizes.

No user relaunch of either application is required for these transitions.

## Self-Healing Behavior

The controller monitors KWin window changes.

If the ChatGPT PWA is closed while the workspace controller is active, the
controller requests `kde-ai-chatgpt.service` through the systemd user manager.

The service relaunches the ChatGPT PWA, after which the controller restores
the appropriate workspace layout.

Window events are debounced before workspace evaluation so that bursts of
KWin events do not immediately trigger independent layout operations.

## KWin Package

The persistent KWin package is stored in the repository at:

`scripts/kwin/packages/kde-ai-lab-workspace/`

The package contains:

- `metadata.json`
- `contents/code/main.js`

The package ID is:

`kde-ai-lab-workspace`

When installed, the package is placed under:

`~/.local/share/kwin/scripts/kde-ai-lab-workspace/`

KWin enables the controller through the `Plugins` group in `kwinrc` using:

`kde-ai-lab-workspaceEnabled=true`

## Installation

The workspace controller is installed with:

`scripts/install-kde-ai-workspace.sh`

The installer:

- Verifies required KDE, KWin, D-Bus, and systemd commands.
- Verifies that the repository contains the KWin package and systemd user unit.
- Installs the KWin package if it is not already installed.
- Upgrades the existing KWin package when it is already installed.
- Installs `kde-ai-chatgpt.service` into the user's systemd configuration.
- Reloads the systemd user manager.
- Enables the KDE AI Lab KWin plugin in `kwinrc`.
- Requests a KWin reconfiguration.
- Verifies that the workspace controller is loaded.
- Verifies that the systemd user unit is installed.

The installer is intended to be safely repeatable. Running it again upgrades
the existing package and refreshes the installed systemd unit without
requiring manual cleanup.

## Installation Verification

The installer has been verified on Fedora in both of the following states:

1. Existing installation:
   The installed KWin package was detected and successfully upgraded.

2. Clean application state:
   The KWin controller was unloaded, the plugin was disabled, the installed
   KWin package was removed, and the installed systemd user unit was removed.
   Running the installer then restored the complete workspace integration.

After clean installation, verification confirmed that:

- The KWin package was installed.
- The KWin plugin was enabled.
- The workspace controller was loaded.
- The systemd user unit was installed.
- The installed KWin `main.js` matched the repository copy.
- The installed systemd service matched the repository copy.
