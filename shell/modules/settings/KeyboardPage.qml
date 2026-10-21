import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.widgets

// Keyboard layouts and repeat, pointer and touchpad, and the shortcut list. Values go to
// desktop.conf; Compositor turns them into Hyprland input options.
ColumnLayout {
    id: page
    readonly property string description: "Keyboard layouts, typing, mouse and touchpad, and every keyboard shortcut."
    spacing: 14

    // xkb layout codes; extend freely, Hyprland accepts any xkb layout.
    readonly property var known: [["us", "English (US)"], ["gb", "English (UK)"], ["in", "Indian"], ["de", "German"], ["fr", "French"], ["es", "Spanish"], ["it", "Italian"], ["pt", "Portuguese"], ["br", "Portuguese (Brazil)"], ["nl", "Dutch"], ["se", "Swedish"], ["no", "Norwegian"], ["dk", "Danish"], ["fi", "Finnish"], ["pl", "Polish"], ["cz", "Czech"], ["hu", "Hungarian"], ["ro", "Romanian"], ["tr", "Turkish"], ["gr", "Greek"], ["ru", "Russian"], ["ua", "Ukrainian"], ["ara", "Arabic"], ["il", "Hebrew"], ["ir", "Persian"], ["jp", "Japanese"], ["kr", "Korean"], ["cn", "Chinese"], ["th", "Thai"], ["vn", "Vietnamese"]]
    readonly property var layouts: Config.kbLayout.split(",").filter(l => l)
    function nameOf(code) {
        return (known.find(k => k[0] === code) ?? [code, code])[1];
    }
    function setLayouts(list) {
        Config.set("kb_layout", list.join(","));
    }

    SettingsBox {
        Repeater {
            model: page.layouts
            SettingsRow {
                required property string modelData
                required property int index
                title: page.nameOf(modelData)
                description: index === 0 ? "Used when you log in" : ""
                Row {
                    spacing: 6
                    Button {
                        visible: index > 0
                        text: "Make first"
                        onClicked: page.setLayouts([modelData, ...page.layouts.filter(l => l !== modelData)])
                    }
                    Button {
                        visible: page.layouts.length > 1
                        text: "Remove"
                        onClicked: page.setLayouts(page.layouts.filter(l => l !== modelData))
                    }
                }
            }
        }
        SettingsRow {
            title: "Add a layout"
            Choice {
                placeholder: "Choose a language"
                options: page.known.filter(k => !page.layouts.includes(k[0])).map(k => ({ value: k[0], label: k[1] }))
                onPicked: v => page.setLayouts([...page.layouts, v])
            }
        }
        SettingsRow {
            visible: page.layouts.length > 1
            title: "Switch layouts with"
            Choice {
                options: [{ value: "alt_shift", label: "Alt + Shift" }, { value: "ctrl_shift", label: "Ctrl + Shift" }, { value: "caps", label: "Caps Lock" }, { value: "none", label: "No shortcut" }]
                current: Config.layoutSwitch
                onPicked: v => Config.set("layout_switch", v)
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Caps Lock key"
            description: Config.layoutSwitch === "caps" && page.layouts.length > 1 ? "Caps Lock switches layouts right now" : ""
            Choice {
                options: [{ value: "caps", label: "Caps Lock" }, { value: "escape", label: "Acts as Escape" }, { value: "ctrl", label: "Acts as Ctrl" }]
                current: Config.capsLock
                onPicked: v => Config.set("caps_lock", v)
            }
        }
        SettingsRow {
            title: "Repeat delay"
            description: "How long to hold a key before it repeats"
            SettingsSlider {
                value: Config.repeatDelay
                min: 150
                max: 1000
                step: 50
                unit: " ms"
                onPicked: v => Config.set("repeat_delay", v)
            }
        }
        SettingsRow {
            title: "Repeat speed"
            SettingsSlider {
                value: Config.repeatRate
                min: 10
                max: 60
                step: 5
                unit: "/s"
                onPicked: v => Config.set("repeat_rate", v)
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Pointer speed"
            SettingsSlider {
                value: Math.round(Config.pointerSpeed * 10) / 10
                min: -1
                max: 1
                step: 0.1
                format: v => v === 0 ? "Default" : (v > 0 ? "+" : "") + v.toFixed(1)
                onPicked: v => Config.set("pointer_speed", v.toFixed(1))
            }
        }
        SettingsRow {
            title: "Natural scrolling"
            description: "Content follows your fingers on the touchpad"
            Switch {
                checked: Config.naturalScroll
                onToggled: Config.set("natural_scroll", Config.naturalScroll ? "off" : "on")
            }
        }
        SettingsRow {
            title: "Tap to click"
            Switch {
                checked: Config.tapToClick
                onToggled: Config.set("tap_to_click", Config.tapToClick ? "off" : "on")
            }
        }
    }

    T {
        text: "Keyboard shortcuts"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        Repeater {
            model: [["Super+Space", "Ask Grace / search apps"], ["Super+N", "Control center"], ["Super+L", "Lock the screen"], ["Super+I", "Settings"], ["Super+Return or Super+T", "Terminal (CandySole)"], ["Super+E", "Files"], ["Super+Q", "Close window"], ["Super+F / Super+M", "Fullscreen / maximize"], ["Super+V", "Float or tile the window"], ["Super+arrows", "Move focus"], ["Super+Shift+arrows", "Move the window"], ["Super+1…9", "Go to a workspace"], ["Super+Shift+1…9", "Send the window to a workspace"], ["Print", "Screenshot to Pictures/Screenshots"], ["Super+Shift+Q", "Log out"]]
            SettingsRow {
                required property var modelData
                title: modelData[1]
                T {
                    text: modelData[0]
                    color: Theme.textSecondary
                    font.family: "Fira Code"
                    font.pixelSize: 12
                }
            }
        }
        SettingsRow {
            title: "Add your own shortcuts"
            description: "In ~/.config/grace/hyprland.conf, e.g. bind = SUPER, B, exec, cottoncandy"
            link: true
            onActivated: Quickshell.execDetached(["grace-launch", "editor", Config.dir + "/hyprland.conf"])
        }
    }
}
