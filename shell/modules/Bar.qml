import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// One per monitor: the top bar plus the panels that open from it.
Scope {
    id: scope
    required property ShellScreen modelData

    PanelWindow {
        id: bar
        screen: scope.modelData
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Theme.barHeight
        color: "transparent"
        WlrLayershell.namespace: "grace-bar"

        Rectangle {
            anchors.fill: parent
            color: Theme.bar
        }

        BarPill {
            anchors.left: parent.left
            anchors.leftMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            active: Ui.launcherOpen && Ui.onScreen(scope.modelData)
            onClicked: Ui.toggleLauncher()
            T {
                text: "Activities"
                color: "#dfe2ea"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        // "Ask Grace" field; with AI switched off it is plain app search.
        Rectangle {
            anchors.centerIn: parent
            width: 230
            height: 22
            radius: 11
            color: askMouse.containsMouse ? Theme.controlStrong : Qt.rgba(1, 1, 1, 0.06)
            border.color: Theme.hair
            Behavior on color { ColorAnimation { duration: Theme.fast } }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Config.ai ? "spark" : "search"
                    size: 14
                    color: Config.ai ? Theme.accent.fg : Theme.textSecondary
                }
                T {
                    text: Config.ai ? "Ask Grace…" : "Search…"
                    color: "#aeb3c0"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: kbd.implicitWidth + 10
                height: 16
                radius: 5
                color: Theme.control
                T {
                    id: kbd
                    anchors.centerIn: parent
                    text: "Super Space"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
            MouseArea {
                id: askMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Ui.toggleLauncher()
            }
        }

        BarPill {
            id: tray
            anchors.right: parent.right
            anchors.rightMargin: Theme.gap
            anchors.verticalCenter: parent.verticalCenter
            active: Ui.ccOpen && Ui.onScreen(scope.modelData)
            onClicked: Ui.toggleCc()

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: Approvals.pending.length > 0
                width: 6
                height: 6
                radius: 3
                color: Theme.accent.fg
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: System.wifiOn ? "wifi" : "wifioff"
                size: 14
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: System.hasAudio
                name: System.muted ? "mute" : "volume"
                size: 14
            }
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: System.hasBattery
                name: "battery"
                size: 14
            }
            T {
                visible: System.hasBattery
                text: System.batteryPercent
                color: "#dfe2ea"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            T {
                text: Qt.formatDateTime(clock.date, "ddd HH:mm")
                color: "#dfe2ea"
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }

    ControlCenter {
        screen: scope.modelData
        bar: bar
    }
    Launcher {
        screen: scope.modelData
        bar: bar
    }
    Popups {
        screen: scope.modelData
        bar: bar
    }
}
