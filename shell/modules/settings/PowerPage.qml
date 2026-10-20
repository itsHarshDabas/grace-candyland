import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

// Power mode (power-profiles-daemon), battery (UPower), and the idle timers in services/Idle.qml.
ColumnLayout {
    id: page
    readonly property string description: "Battery, power mode, and when the screen turns off or the PC sleeps."
    spacing: 14

    readonly property var minutes: [0, 1, 2, 5, 10, 15, 20, 30, 45, 60, 90, 120]
    function minuteOptions(neverLabel) {
        return minutes.map(m => ({ value: m, label: m === 0 ? neverLabel : m < 60 ? `${m} min` : `${m / 60} h` }));
    }

    SettingsBox {
        visible: System.hasBattery
        SettingsRow {
            title: "Battery"
            description: System.batteryText + (UPower.onBattery ? " · on battery" : " · plugged in")
            Rectangle {
                width: 120
                height: 10
                radius: 5
                color: Theme.track
                Rectangle {
                    width: parent.width * System.batteryLevel
                    height: parent.height
                    radius: 5
                    color: System.batteryLevel < 0.15 ? Theme.error : Theme.success
                }
            }
        }
        SettingsRow {
            visible: System.battery?.healthSupported ?? false
            title: "Battery health"
            description: "How much charge it holds compared to when it was new"
            T {
                text: Math.round(System.battery?.healthPercentage ?? 0) + "%"
                color: Theme.textSecondary
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Power mode"
            description: PowerProfiles.degradationReason !== PerformanceDegradationReason.None ? "Performance is limited right now (the PC is too hot, or the lid is closed)" : "Balanced suits most uses; Power Saver stretches the battery"
            Segmented {
                options: [{ value: PowerProfile.PowerSaver, label: "Power Saver" }, { value: PowerProfile.Balanced, label: "Balanced" }].concat(PowerProfiles.hasPerformanceProfile ? [{ value: PowerProfile.Performance, label: "Performance" }] : [])
                current: PowerProfiles.profile
                onPicked: v => PowerProfiles.profile = v
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Turn off the screen"
            description: "After this long without using the mouse or keyboard. Playing videos keep it on."
            Choice {
                options: page.minuteOptions("Never")
                current: Config.screenOffAfter
                onPicked: v => Config.set("screen_off_after", v)
            }
        }
        SettingsRow {
            title: "Sleep automatically"
            description: "Suspends the PC after this long idle"
            Choice {
                options: page.minuteOptions("Never")
                current: Config.suspendAfter
                onPicked: v => Config.set("suspend_after", v)
            }
        }
        SettingsRow {
            title: "Screen lock"
            description: "Lock timing is in Privacy & Security"
            link: true
            onActivated: Ui.settingsPage = "Privacy & Security"
        }
    }
}
