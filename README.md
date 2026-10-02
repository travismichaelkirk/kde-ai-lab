# KDE AI Lab

KDE AI Lab is a portable KDE Plasma environment for AI-assisted development, testing, diagnostics, and workflow automation.

The project is designed to reduce the mechanical friction around AI-assisted technical work while preserving deliberate testing, verification, and human understanding.

## Core Philosophy

### Automate friction. Preserve verification.

Automation should remove repetitive mechanical work without removing the checkpoints that make troubleshooting reliable.

Changes should be made deliberately, tested independently, verified, and only then incorporated into the known-good project state.

### Learn concepts when the project creates a reason to understand them.

KDE AI Lab is also a learning project. New technologies, tools, and concepts will be introduced when the project creates a practical reason to use them.

The goal is not simply to produce a working environment, but to understand why the environment is designed the way it is.

## Initial Use Case

The first implementation of KDE AI Lab will optimize an existing AI-assisted Android and Tasker development workflow built around:

- ChatGPT
- KDE Plasma
- Android
- Tasker
- ADB
- scrcpy
- Konsole
- KWin
- Git and GitHub

The initial reference implementation will be developed on Fedora KDE Plasma.

## Portability Goal

The project will be designed so that the same environment can eventually be reproduced across multiple KDE Plasma distributions, including:

- Fedora
- Arch Linux
- Debian
- MX Linux

Distribution-specific behavior will be isolated wherever practical so that the portable core remains reusable.

## Development Method

KDE AI Lab will be developed incrementally.

Each capability will follow a deliberate cycle:

1. Build
2. Test
3. Observe
4. Refine
5. Verify
6. Document
7. Commit
8. Push
9. Tag meaningful known-good milestones

The project will grow from real workflow requirements rather than from speculative features.

## Validated Workspace Milestones

### v0.2-orchestration

The multi-window KDE AI Lab workspace orchestration was validated on the Fedora KDE reference workstation using a two-monitor configuration.

A true cold-start test was performed with all managed Monitor 2 workspace components stopped before launch. The workspace was then reconstructed using the single command:

```bash
scripts/launcher/ai-terminal-workspace.sh

```

The validated result was:

- Monitor 1: ChatGPT remained maximized.
- Monitor 2 left: dedicated KDE AI Lab Konsole.
- Monitor 2 middle: Android device display through scrcpy.
- Monitor 2 right: dedicated AUX Chrome browser.
- An unrelated ordinary Konsole session remained running and was not managed or repositioned by KDE AI Lab.

The cold-start test confirmed that the launcher can independently start the managed workspace components and that the KWin workspace controller can reconstruct the intended two-monitor layout without manual window positioning.

The implementation represented by tag `v0.2-orchestration` is therefore the known-good baseline for multi-window workspace orchestration.
