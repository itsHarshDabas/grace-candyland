pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config

// Idle timers from desktop.conf (minutes, 0 = never). They respect idle inhibitors, so a playing
// video keeps the screen on. hypridle only handles "lock before sleep" (see data/hypridle.conf).
Singleton {
    id: root

    IdleMonitor {
        enabled: Config.lockAfter > 0
        timeout: Config.lockAfter * 60
        onIsIdleChanged: if (isIdle) Ui.lock()
    }
    IdleMonitor {
        enabled: Config.screenOffAfter > 0
        timeout: Config.screenOffAfter * 60
        onIsIdleChanged: Hyprland.dispatch(isIdle ? "dpms off" : "dpms on")
    }
    IdleMonitor {
        enabled: Config.suspendAfter > 0
        timeout: Config.suspendAfter * 60
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }
}
