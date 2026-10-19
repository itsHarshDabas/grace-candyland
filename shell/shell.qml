//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules

// Grace Candyland shell. Run with: qs -p /usr/share/grace-candyland/shell
ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }
    Variants {
        model: Quickshell.screens
        Dock {}
    }
    Settings {}
    Lock {
        id: lock
    }
    Connections {
        target: Ui
        function onLockRequested() {
            lock.lock();
        }
    }

    // Bound in hyprland.conf as "global, quickshell:<name>".
    GlobalShortcut {
        name: "launcher"
        description: "Ask Grace / search apps"
        onPressed: Ui.toggleLauncher()
    }
    GlobalShortcut {
        name: "lock"
        description: "Lock the screen"
        onPressed: Ui.lock()
    }
    GlobalShortcut {
        name: "controlcenter"
        description: "Open the control center"
        onPressed: Ui.toggleCc()
    }

    // `qs -p <shell> ipc call <target> <function>`, used by grace-settings and scripts.
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            Ui.toggleLauncher();
        }
    }
    IpcHandler {
        target: "controlcenter"
        function toggle(): void {
            Ui.toggleCc();
        }
    }
    // hypridle locks through this (see data/hypridle.conf).
    IpcHandler {
        target: "lock"
        function lock(): void {
            Ui.lock();
        }
    }
    IpcHandler {
        target: "settings"
        function open(): void {
            Ui.openSettings();
        }
    }

    // Singletons load lazily; touch the ones that must run from the start.
    Component.onCompleted: [Compositor.reduceMotion, Approvals.pending, Notifs.list]
}
