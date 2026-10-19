import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Opens from the tray pill. Its top, right and bottom edges sit on the same gap grid as the windows.
// The top section stays put; only the notification list scrolls.
PanelWindow {
    id: win
    required property var bar
    readonly property bool open: Ui.ccOpen && Ui.onScreen(bar.screen)

    visible: open || fade.running
    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: Theme.gap
        right: Theme.gap
        bottom: Theme.gap
    }
    exclusiveZone: 0
    implicitWidth: Theme.panelWidth
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "grace-panel"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [win, win.bar]
        active: win.open
        onCleared: Ui.ccOpen = false
    }

    property bool powerMenu: false
    onOpenChanged: {
        powerMenu = false;
        if (open)
            System.refresh();
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        radius: Config.rounding + 8
        color: Theme.panel
        border.color: Theme.hair
        focus: win.open
        Keys.onEscapePressed: Ui.ccOpen = false

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: Theme.normal; easing.type: Easing.OutCubic } }
        transform: Translate {
            x: win.open ? 0 : 16
            Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // Header: battery (or the date), Settings and Power.
            RowLayout {
                Layout.fillWidth: true
                spacing: 7
                Icon {
                    visible: System.hasBattery
                    name: "battery"
                    size: 14
                }
                T {
                    Layout.fillWidth: true
                    text: System.hasBattery ? System.batteryText : Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: "#c9ccd6"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
                RoundButton {
                    icon: "settings"
                    onClicked: Ui.openSettings()
                }
                RoundButton {
                    icon: "power"
                    onClicked: win.powerMenu = !win.powerMenu
                }
            }
            RowLayout {
                visible: win.powerMenu
                Layout.fillWidth: true
                spacing: 6
                Item { Layout.fillWidth: true }
                Button {
                    text: "Lock"
                    onClicked: Ui.lock()
                }
                Button {
                    text: "Log out"
                    onClicked: Hyprland.dispatch("exit")
                }
                Button {
                    text: "Restart"
                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                }
                Button {
                    text: "Power off"
                    onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: System.wifiOn ? "wifi" : "wifioff"
                    label: "Wi-Fi"
                    subtitle: System.wifiOn ? System.wifiName : "Off"
                    on: System.wifiOn
                    onClicked: System.toggleWifi()
                }
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "bluetooth"
                    label: "Bluetooth"
                    subtitle: !System.hasBt ? "Unavailable" : System.btOn ? System.btDevice : "Off"
                    on: System.btOn
                    available: System.hasBt
                    onClicked: System.toggleBt()
                }
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "bell"
                    label: "Do Not Disturb"
                    on: Config.dnd
                    onClicked: Config.toggle("dnd")
                }
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "moon"
                    label: "Dark Style"
                    on: Config.style === "dark"
                    onClicked: Config.set("style", Config.style === "dark" ? "light" : "dark")
                }
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "gauge"
                    label: "Power Mode"
                    subtitle: System.profileName
                    on: System.profileName !== "Balanced"
                    onClicked: System.cycleProfile()
                }
                QuickToggle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    icon: "nightlight"
                    label: "Night Light"
                    on: Config.nightLight
                    onClicked: Config.toggle("night_light")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                spacing: 14
                RowLayout {
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    spacing: 12
                    Icon {
                        name: System.muted ? "mute" : "volume"
                        MouseArea {
                            anchors.fill: parent
                            onClicked: System.toggleMute()
                        }
                    }
                    Slider {
                        Layout.fillWidth: true
                        enabled: System.hasAudio
                        value: System.muted ? 0 : System.volume
                        onMoved: v => System.setVolume(v)
                    }
                }
                RowLayout {
                    visible: System.brightness >= 0
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    spacing: 12
                    Icon { name: "sun" }
                    Slider {
                        Layout.fillWidth: true
                        value: System.brightness
                        onMoved: v => System.setBrightness(v)
                    }
                }
            }

            LocalAiCard {
                Layout.fillWidth: true
                active: win.open
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2
                Layout.rightMargin: 2
                Layout.bottomMargin: -6
                T {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: "#8d93a2"
                    font.pixelSize: 11
                }
                T {
                    text: "Clear all"
                    color: clearMouse.containsMouse ? Theme.text : "#8d93a2"
                    font.pixelSize: 11
                    visible: Notifs.list.length > 0
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: Notifs.clearAll()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: list
                    anchors.fill: parent
                    spacing: 8
                    bottomMargin: 18
                    boundsBehavior: Flickable.StopAtBounds
                    // Pending approvals stay pinned above everything else.
                    model: Approvals.pending.concat(Notifs.list)
                    delegate: Loader {
                        required property var modelData
                        width: ListView.view.width
                        sourceComponent: modelData.reply !== undefined ? approval : notification
                        Component {
                            id: approval
                            ApprovalCard { request: modelData }
                        }
                        Component {
                            id: notification
                            NotificationCard {
                                notification: modelData
                                onDone: modelData.dismiss()
                            }
                        }
                    }
                }
                T {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No notifications"
                    color: Theme.textTertiary
                    font.pixelSize: 12
                }
                // Soft fade at the bottom of the list instead of a scrollbar.
                Rectangle {
                    visible: list.contentHeight > list.height
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 28
                    gradient: Gradient {
                        GradientStop { position: 0; color: "transparent" }
                        GradientStop { position: 1; color: Theme.panel }
                    }
                }
            }
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
