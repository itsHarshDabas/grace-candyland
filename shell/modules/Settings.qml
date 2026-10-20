import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Grace Settings. Each page is a file in settings/ (see `pages`). Desktop options write desktop.conf,
// which Compositor applies live; the rest talk to the system (NetworkManager, BlueZ, PipeWire...).
FloatingWindow {
    id: win
    readonly property string page: Ui.settingsPage
    property string search: ""

    title: "Settings"
    visible: Ui.settingsOpen
    onVisibleChanged: Ui.settingsOpen = visible
    implicitWidth: 1000
    implicitHeight: 680
    minimumSize: Qt.size(760, 480)
    color: Theme.window

    readonly property var groups: [
        { title: "", items: [["Wi-Fi", "wifi"], ["Bluetooth", "bluetooth"], ["Displays", "display"], ["Sound", "volume"], ["Power", "battery"]] },
        { title: "Desktop", items: [["Appearance", "appearance"], ["Windows & Workspaces", "windows"], ["Keyboard & Shortcuts", "keyboard"]] },
        { title: "Intelligence", items: [["AI & Models", "spark"], ["Agents", "agent"]] },
        { title: "System", items: [["Privacy & Security", "shield"], ["Updates & Software", "download"], ["About", "info"]] }
    ]
    // Page title -> file in settings/
    readonly property var pages: ({
            "Wi-Fi": "WifiPage",
            "Bluetooth": "BluetoothPage",
            "Displays": "DisplaysPage",
            "Sound": "SoundPage",
            "Power": "PowerPage",
            "Appearance": "AppearancePage",
            "Windows & Workspaces": "WindowsPage",
            "Keyboard & Shortcuts": "KeyboardPage",
            "AI & Models": "AiPage",
            "Agents": "AgentsPage",
            "Privacy & Security": "PrivacyPage",
            "Updates & Software": "UpdatesPage",
            "About": "AboutPage"
        })

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Title bar: traffic lights on the left, title centered.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: Theme.titlebar
            TrafficLights {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                onClose: Ui.settingsOpen = false
                onMinimize: Ui.settingsOpen = false
                onMaximize: Hyprland.dispatch("fullscreen 1")
            }
            T {
                anchors.centerIn: parent
                text: "Settings"
                color: "#d6d9e1"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.subtle
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Sidebar
            Rectangle {
                Layout.preferredWidth: 232
                Layout.fillHeight: true
                color: Theme.sidebar
                Rectangle {
                    anchors.right: parent.right
                    width: 1
                    height: parent.height
                    color: Theme.subtle
                }
                Flickable {
                    anchors.fill: parent
                    anchors.margins: 8
                    anchors.topMargin: 10
                    contentHeight: side.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: side
                        width: parent.width
                        spacing: 2

                        Rectangle {
                            width: parent.width - 8
                            x: 4
                            height: 32
                            radius: Theme.radiusMd
                            color: Theme.control
                            Icon {
                                id: searchIcon
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                name: "search"
                                size: 14
                                color: Theme.textSecondary
                            }
                            TextInput {
                                id: searchInput
                                anchors.left: searchIcon.right
                                anchors.leftMargin: 8
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                onTextEdited: win.search = text.toLowerCase()
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 13
                                T {
                                    visible: !searchInput.text
                                    text: "Search settings"
                                    color: Theme.textSecondary
                                }
                            }
                        }
                        Item { width: 1; height: 8 }

                        Repeater {
                            model: win.groups
                            Column {
                                id: group
                                required property var modelData
                                width: side.width
                                spacing: 2
                                readonly property var matches: modelData.items.filter(i => i[0].toLowerCase().includes(win.search))
                                visible: matches.length > 0
                                T {
                                    visible: group.modelData.title !== "" && win.search === ""
                                    text: group.modelData.title
                                    color: "#7a8090"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    leftPadding: 10
                                    topPadding: 12
                                    bottomPadding: 4
                                }
                                Repeater {
                                    model: group.matches
                                    Rectangle {
                                        id: item
                                        required property var modelData
                                        readonly property bool selected: win.page === modelData[0]
                                        width: group.width
                                        height: 34
                                        radius: Theme.radiusMd
                                        color: selected ? Theme.controlStrong : itemMouse.containsMouse ? Theme.control : "transparent"
                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 10
                                            Icon {
                                                anchors.verticalCenter: parent.verticalCenter
                                                name: item.modelData[1]
                                                color: item.selected ? Theme.accent.fg : Theme.textControl
                                            }
                                            T {
                                                text: item.modelData[0]
                                                color: item.selected ? "white" : "#d2d5de"
                                            }
                                        }
                                        MouseArea {
                                            id: itemMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: Ui.settingsPage = item.modelData[0]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Page
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: pageCol.implicitHeight + 44
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: pageCol
                    width: Math.min(parent.width - 60, 760)
                    x: (parent.width - width) / 2
                    y: 22
                    spacing: 14

                    ColumnLayout {
                        spacing: 2
                        Layout.bottomMargin: 2
                        T {
                            text: win.page
                            color: Theme.textStrong
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                        T {
                            Layout.fillWidth: true
                            text: pageLoader.item?.description ?? ""
                            color: Theme.textSecondary
                            wrapMode: Text.Wrap
                        }
                    }

                    // Pages load only while shown, so their system polling stops when you leave them.
                    Loader {
                        id: pageLoader
                        Layout.fillWidth: true
                        active: win.visible
                        source: Qt.resolvedUrl("settings/" + win.pages[win.page] + ".qml")
                    }
                }
            }
        }
    }
}
