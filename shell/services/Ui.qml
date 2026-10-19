pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which shell surfaces are open. Popups only show on the focused monitor.
Singleton {
    property bool ccOpen: false
    property bool launcherOpen: false
    property bool settingsOpen: false
    readonly property string screenName: Hyprland.focusedMonitor?.name ?? ""

    function onScreen(screen) {
        return screenName === "" || screen?.name === screenName;
    }
    function toggleCc() {
        launcherOpen = false;
        ccOpen = !ccOpen;
    }
    function toggleLauncher() {
        ccOpen = false;
        launcherOpen = !launcherOpen;
    }
    signal lockRequested
    function lock() {
        ccOpen = false;
        launcherOpen = false;
        lockRequested();
    }
    function openSettings() {
        ccOpen = false;
        launcherOpen = false;
        settingsOpen = true;
    }
}
