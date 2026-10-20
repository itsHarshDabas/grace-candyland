import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets

ColumnLayout {
    readonly property string description: "How GraceOS looks and moves. Every option here also lives in a plain config file, if you prefer editing that."
    spacing: 14

    SettingsBox {
        SettingsRow {
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
        SettingsRow {
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

    SettingsBox {
        SettingsRow {
            title: "Window gaps"
            description: "Space between windows and the screen edges"
            SettingsSlider {
                value: Config.gaps
                max: 24
                step: 2
                unit: " px"
                onPicked: v => Config.set("gaps", v)
            }
        }
        SettingsRow {
            title: "Corner roundness"
            SettingsSlider {
                value: Config.rounding
                max: 22
                unit: " px"
                onPicked: v => Config.set("rounding", v)
            }
        }
        SettingsRow {
            title: "Background blur"
            description: Compositor.lite ? "Off in lite mode (no GPU, or under 4 GB of RAM)" : "Frosted glass on the top bar, dock and panels"
            Switch {
                checked: Config.blur
                onToggled: Config.set("blur", Config.blur ? "off" : "on")
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Animations"
            description: Compositor.reduceMotion ? "Off while your system asks for reduced motion" : Compositor.lite ? "Off in lite mode" : "Follows your system's reduce-motion setting automatically"
            Segmented {
                options: [{ value: "off", label: "Off" }, { value: "calm", label: "Calm" }, { value: "smooth", label: "Smooth" }, { value: "snappy", label: "Snappy" }]
                current: Config.animations
                onPicked: v => Config.set("animations", v)
            }
        }
        SettingsRow {
            title: "Dock"
            Segmented {
                options: [{ value: "hover", label: "On hover" }, { value: "always", label: "Always" }, { value: "never", label: "Never" }]
                current: Config.dock
                onPicked: v => Config.set("dock", v)
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Get themes & extensions"
            description: "Browse community themes, including AUR packages, in your browser"
            link: true
            onActivated: Quickshell.execDetached(["xdg-open", "https://aur.archlinux.org/packages?K=gtk-theme"])
        }
        SettingsRow {
            title: "Edit config file"
            description: "~/.config/grace/desktop.conf"
            link: true
            onActivated: Quickshell.execDetached(["grace-launch", "editor", Config.path])
        }
    }
}
