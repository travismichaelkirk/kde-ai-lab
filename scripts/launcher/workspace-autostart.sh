#!/usr/bin/env bash

set -u

PROJECT_ROOT="$HOME/kde-ai-lab"
DESKTOP_1_ID="71829e83-4c15-42bc-bb4c-fe908cf625df"

for ((i=1; i<=30; i++)); do
    if qdbus-qt6 org.kde.KWin /Scripting \
        org.kde.kwin.Scripting.isScriptLoaded \
        kde-ai-lab-workspace 2>/dev/null | grep -qx true; then

        /usr/bin/bash \
            "$PROJECT_ROOT/scripts/launcher/ai-terminal-workspace.sh" || exit 1

        for ((j=1; j<=30; j++)); do
            if pgrep -f '/usr/bin/konsole.*--desktopfile kde-ai-lab-konsole' >/dev/null &&
               pgrep -x scrcpy >/dev/null &&
               pgrep -f 'chrome.*kde-ai-lab-aux' >/dev/null; then

                sleep 2

                qdbus-qt6 org.kde.KWin /VirtualDesktopManager \
                    org.freedesktop.DBus.Properties.Set \
                    org.kde.KWin.VirtualDesktopManager \
                    current "$DESKTOP_1_ID"

                exit $?
            fi

            sleep 1
        done

        printf 'KDE AI Lab: workspace applications not ready\n' >&2
        exit 1
    fi

    sleep 1
done

printf 'KDE AI Lab: KWin controller not ready\n' >&2
exit 1
