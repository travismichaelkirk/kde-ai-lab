# ChatGPT PWA Integration

## Purpose

Integrate the ChatGPT web application with KDE Plasma as a standalone application while preserving a portable, single-monitor-first workflow.

The goal is to reduce mechanical friction around AI-assisted development without removing deliberate testing and verification.

## Current Platform

Initial implementation and verification:

- Fedora KDE Plasma
- Google Chrome
- Wayland
- ChatGPT installed as a Chrome web application

## Design Principles

- Single-monitor-first
- One virtual desktop by default
- Multi-monitor support is optional
- Avoid hard-coded screen coordinates
- Preserve manual control after automation is applied
- Detect local application properties rather than assuming they are identical across distributions
- Do not overwrite unrelated user KDE configuration

## ChatGPT PWA

Chrome generated the local desktop launcher:

```text
~/.local/share/applications/chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default.desktop
```

The launcher currently contains:

```ini
[Desktop Entry]
Version=1.0
Terminal=false
Type=Application
Name=ChatGPT
Exec=/opt/google/chrome/google-chrome --profile-directory=Default --app-id=cadlkienfkclaiaibeoongdcgmdikeeg
Icon=chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default
StartupWMClass=crx_cadlkienfkclaiaibeoongdcgmdikeeg
```

## KWin Application Detection

KWin identifies the ChatGPT PWA as:

```text
desktopFile:
chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default

resourceClass:
chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default

resourceName:
chrome
```

Ordinary Google Chrome is identified separately:

```text
desktopFile:
google-chrome

resourceClass:
google-chrome

resourceName:
chrome
```

This confirms that KWin can target the ChatGPT PWA without affecting normal Chrome windows.

## KWin Rule

A KWin Window Rule named:

```text
ChatGPT PWA
```

matches the ChatGPT application class exactly.

Current behavior:

- Maximize horizontally on initial launch
- Maximize vertically on initial launch
- Allow manual restore and resize afterward

The rule uses `Apply initially` rather than permanently forcing the maximized state.

Relevant configuration currently appears in:

```text
~/.config/kwinrulesrc
```

Example:

```ini
[rule-id]
Description=ChatGPT PWA
maximizehoriz=true
maximizehorizrule=3
maximizevert=true
maximizevertrule=3
wmclass=chrome-cadlkienfkclaiaibeoongdcgmdikeeg-Default
wmclassmatch=1
```

The complete `kwinrulesrc` should not be copied or overwritten by KDE AI Lab because it may contain unrelated user rules.

Future deployment should add or manage only KDE AI Lab-owned configuration.

## Verification Results

Verified on Fedora:

- ChatGPT launches as a standalone application.
- KDE Application Launcher can launch the ChatGPT PWA.
- ChatGPT and ordinary Chrome have distinct KWin identities.
- ChatGPT launches maximized.
- The user can manually restore and resize the window.
- KWin does not force the window back to maximized after manual resizing.
- Closing the resized window and relaunching ChatGPT causes it to launch maximized again.
- ChatGPT login/session persists.
- The previous conversation is not automatically restored on launch.
- One virtual desktop is currently used.

## Portability Notes

Do not assume:

- Chrome is installed at `/opt/google/chrome/google-chrome`.
- The Chrome profile is named `Default`.
- The generated PWA application ID or KWin application class is identical across machines.
- The user has only KDE AI Lab rules in `kwinrulesrc`.

Future installation tooling should detect the local ChatGPT PWA and merge KDE AI Lab-owned configuration without replacing unrelated KDE configuration.

## Next Investigation

Determine the most useful single-monitor workflow for supporting tools such as:

- Konsole
- ADB / device diagnostics
- Tasker-related command execution
- Pixel screen interaction or mirroring

Additional workspace complexity such as virtual desktops should only be introduced when an actual workflow demonstrates the need.
