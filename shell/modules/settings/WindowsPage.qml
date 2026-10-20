import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services
import qs.widgets

// How windows are placed and focused. Everything maps to desktop.conf (applied by Compositor).
ColumnLayout {
    readonly property string description: "How windows are arranged, focused and moved between workspaces."
    spacing: 14

    SettingsBox {
        SettingsRow {
            title: "Window layout"
            description: "Auto-tile arranges windows for you; Floating lets you drag them freely"
            Segmented {
                options: [{ value: "tile", label: "Auto-tile" }, { value: "float", label: "Floating" }]
                current: Config.layout
                onPicked: v => Config.set("layout", v)
            }
        }
        SettingsRow {
            visible: Config.layout === "tile"
            title: "Tiling style"
            description: Config.tiling === "master" ? "One big main window, the rest stacked beside it" : "Each new window splits the space of the focused one"
            Segmented {
                options: [{ value: "dwindle", label: "Split" }, { value: "master", label: "Main + stack" }]
                current: Config.tiling
                onPicked: v => Config.set("tiling", v)
            }
        }
        SettingsRow {
            title: "Snap floating windows"
            description: "Floating windows stick to screen edges and to each other"
            Switch {
                checked: Config.snap
                onToggled: Config.set("snap", Config.snap ? "off" : "on")
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Focus follows the mouse"
            description: "The window under the pointer gets the keyboard, without clicking"
            Switch {
                checked: Config.followMouse
                onToggled: Config.set("follow_mouse", Config.followMouse ? "off" : "on")
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Workspaces"
            description: "Super+1…9 goes to a workspace, Super+Shift+1…9 sends the window there, Super+scroll moves between them. New workspaces appear as you use them."
        }
        SettingsRow {
            title: "Move and resize"
            description: "Super+drag moves a window, Super+right-drag resizes it, Super+V floats or tiles it"
        }
        SettingsRow {
            title: "All keyboard shortcuts"
            link: true
            onActivated: Ui.settingsPage = "Keyboard & Shortcuts"
        }
    }
}
