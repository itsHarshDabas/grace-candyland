import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Grace Settings. Appearance is built; other pages are listed so the layout is final, but say they're not ready.
// Every control writes desktop.conf, and Compositor applies it live.
FloatingWindow {
    id: win
    property string page: "Appearance"
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
                                            onClicked: win.page = item.modelData[0]
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
                            text: win.page === "Appearance" ? "How GraceOS looks and moves. Every option here also lives in a plain config file, if you prefer editing that." : "This page isn't built yet."
                            color: Theme.textSecondary
                            wrapMode: Text.Wrap
                        }
                    }

                    ColumnLayout {
                        visible: win.page === "Appearance"
                        Layout.fillWidth: true
                        spacing: 14

                        Box {
                            Row_ {
                                title: "Style"
                                Row {
                                    spacing: 12
                                    Repeater {
                                        model: [["light", "Light", "#f6f6f8", "#dfe2ea"], ["dark", "Dark", "#2a2e3a", "#14161c"]]
                                        Rectangle {
                                            id: styleCard
                                            required property var modelData
                                            readonly property bool on: Config.style === modelData[0]
                                            width: 118
                                            height: 92
                                            radius: 10
                                            color: "transparent"
                                            border.width: on ? 2 : 1
                                            border.color: on ? Theme.accent.fill : Theme.hair
                                            Rectangle {
                                                x: 5
                                                y: 5
                                                width: parent.width - 10
                                                height: 60
                                                radius: 7
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0; color: styleCard.modelData[2] }
                                                    GradientStop { position: 1; color: styleCard.modelData[3] }
                                                }
                                            }
                                            T {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                anchors.bottomMargin: 8
                                                text: styleCard.modelData[1]
                                                color: "#c9ccd6"
                                                font.pixelSize: 12
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Config.set("style", styleCard.modelData[0])
                                            }
                                        }
                                    }
                                }
                            }
                            Row_ {
                                title: "Accent color"
                                description: "Used for toggles, sliders, primary buttons and AI icons"
                                Row {
                                    spacing: 9
                                    Repeater {
                                        model: Theme.accentNames
                                        Rectangle {
                                            id: swatch
                                            required property string modelData
                                            readonly property bool on: Config.accent === modelData
                                            width: 22
                                            height: 22
                                            radius: 11
                                            color: Theme.accents[modelData].base
                                            border.width: 1
                                            border.color: Qt.rgba(0, 0, 0, 0.25)
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 30
                                                height: 30
                                                radius: 15
                                                color: "transparent"
                                                border.width: 2
                                                border.color: Qt.rgba(1, 1, 1, 0.85)
                                                visible: swatch.on || swatchMouse.containsMouse
                                            }
                                            MouseArea {
                                                id: swatchMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Config.set("accent", swatch.modelData)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Box {
                            Row_ {
                                title: "Window gaps"
                                description: "Space between windows and the screen edges"
                                SliderValue {
                                    value: Config.gaps
                                    max: 24
                                    step: 2
                                    onPicked: v => Config.set("gaps", v)
                                }
                            }
                            Row_ {
                                title: "Corner roundness"
                                SliderValue {
                                    value: Config.rounding
                                    max: 22
                                    step: 1
                                    onPicked: v => Config.set("rounding", v)
                                }
                            }
                            Row_ {
                                title: "Background blur"
                                description: "Frosted glass on the top bar, dock and panels"
                                Switch {
                                    checked: Config.blur
                                    onToggled: Config.set("blur", Config.blur ? "off" : "on")
                                }
                            }
                            Row_ {
                                title: "Window layout"
                                description: "Auto-tile arranges windows for you; Floating lets you drag them freely"
                                Segmented {
                                    options: [{ value: "tile", label: "Auto-tile" }, { value: "float", label: "Floating" }]
                                    current: Config.layout
                                    onPicked: v => Config.set("layout", v)
                                }
                            }
                        }

                        Box {
                            Row_ {
                                title: "Animations"
                                description: Compositor.reduceMotion ? "Off while your system asks for reduced motion" : "Follows your system's reduce-motion setting automatically"
                                Segmented {
                                    options: [{ value: "off", label: "Off" }, { value: "calm", label: "Calm" }, { value: "smooth", label: "Smooth" }, { value: "snappy", label: "Snappy" }]
                                    current: Config.animations
                                    onPicked: v => Config.set("animations", v)
                                }
                            }
                            Row_ {
                                title: "Dock"
                                Segmented {
                                    options: [{ value: "hover", label: "On hover" }, { value: "always", label: "Always" }, { value: "never", label: "Never" }]
                                    current: Config.dock
                                    onPicked: v => Config.set("dock", v)
                                }
                            }
                        }

                        Box {
                            Row_ {
                                title: "Get themes & extensions"
                                description: "Browse community themes, including AUR packages, in your browser"
                                link: true
                                onActivated: Quickshell.execDetached(["xdg-open", "https://aur.archlinux.org/packages?K=gtk-theme"])
                            }
                            Row_ {
                                title: "Edit config file"
                                description: "~/.config/grace/desktop.conf"
                                link: true
                                onActivated: Quickshell.execDetached(["grace-launch", "editor", Config.path])
                            }
                        }
                    }
                }
            }
        }
    }

    component Box: Rectangle {
        default property alias rows: rowsCol.data
        Layout.fillWidth: true
        implicitHeight: rowsCol.implicitHeight
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.035)
        border.color: Qt.rgba(1, 1, 1, 0.06)
        Column {
            id: rowsCol
            width: parent.width
        }
    }

    // A settings row: title and description on the left, the control on the right.
    // Rows after the first get a hairline on top.
    component Row_: Item {
        id: r
        property string title
        property string description
        property bool link: false
        default property alias control: slot.data
        signal activated

        width: parent?.width ?? 0
        implicitHeight: Math.max(textCol.implicitHeight, slot.childrenRect.height) + 24
        Rectangle {
            visible: r.parent && r.parent.children[0] !== r
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.05)
        }
        Column {
            id: textCol
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - slot.childrenRect.width - 60
            spacing: 2
            T {
                width: parent.width
                text: r.title
                color: "#e9ebf0"
            }
            T {
                width: parent.width
                visible: r.description !== ""
                text: r.description
                color: "#7f8595"
                font.pixelSize: 12
            }
        }
        Item {
            id: slot
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
        Icon {
            visible: r.link
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            name: "chevronright"
            color: Theme.textSecondary
        }
        MouseArea {
            visible: r.link
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: r.activated()
        }
    }

    component SliderValue: Row {
        id: sv
        property int value
        property int max
        property int step: 1
        signal picked(int value)
        spacing: 10
        Slider {
            width: 200
            anchors.verticalCenter: parent.verticalCenter
            value: sv.value / sv.max
            onMoved: v => {
                const n = Math.round(v * sv.max / sv.step) * sv.step;
                if (n !== sv.value)
                    sv.picked(n);
            }
        }
        T {
            width: 38
            text: sv.value + " px"
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }
}
