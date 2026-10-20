import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Monitors from `hyprctl monitors all -j`. Changes apply at once and are saved, one line per
// monitor, to ~/.config/grace/monitors.conf (sourced by the Grace Hyprland config).
ColumnLayout {
    id: page
    readonly property string description: "Resolution, scale and rotation for each screen, plus brightness and Night Light."
    spacing: 14

    property var monitors: []
    // name -> { mode, scale, transform, disabled }: what we write to monitors.conf
    property var chosen: ({})
    readonly property string confPath: Config.dir + "/monitors.conf"

    Process {
        id: query
        command: ["hyprctl", "monitors", "all", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let list = [];
                try {
                    list = JSON.parse(text);
                } catch (e) {}
                const c = {};
                for (const m of list)
                    c[m.name] = page.chosen[m.name] ?? {
                        mode: `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}`,
                        scale: m.scale,
                        transform: m.transform,
                        disabled: m.disabled
                    };
                page.chosen = c;
                page.monitors = list;
            }
        }
    }
    Timer {
        id: requery
        interval: 700
        onTriggered: query.running = true
    }
    FileView {
        id: conf
        path: page.confPath
    }

    function line(name) {
        const c = chosen[name];
        return c.disabled ? `monitor = ${name}, disable` : `monitor = ${name}, ${c.mode}, auto, ${c.scale}, transform, ${c.transform}`;
    }
    function apply(name, change) {
        chosen[name] = Object.assign({}, chosen[name], change);
        chosen = Object.assign({}, chosen);
        Quickshell.execDetached(["hyprctl", "keyword", "monitor", line(name).replace(/^monitor = /, "")]);
        conf.setText("# Written by Grace Settings → Displays. One line per monitor.\n" + Object.keys(chosen).map(n => line(n)).join("\n") + "\n");
        requery.restart();
    }

    Repeater {
        model: page.monitors
        ColumnLayout {
            id: mon
            required property var modelData
            readonly property var c: page.chosen[modelData.name] ?? {}
            Layout.fillWidth: true
            spacing: 6

            T {
                text: (mon.modelData.description || mon.modelData.name) + (mon.modelData.focused ? " · main" : "")
                color: Theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            SettingsBox {
                SettingsRow {
                    visible: page.monitors.length > 1
                    title: "Use this display"
                    Switch {
                        checked: !mon.c.disabled
                        onToggled: page.apply(mon.modelData.name, { disabled: !mon.c.disabled })
                    }
                }
                SettingsRow {
                    visible: !mon.c.disabled
                    title: "Resolution"
                    description: `${mon.modelData.width} × ${mon.modelData.height} at ${Math.round(mon.modelData.refreshRate)} Hz`
                    Choice {
                        // "1920x1080@60.00Hz" -> "1920x1080@60.00"; the list repeats close refresh rates, keep the first.
                        options: [...new Set(mon.modelData.availableModes.map(s => s.replace(/Hz$/, "")))].map(s => ({ value: s, label: s.replace("x", " × ").replace(/@(\d+)\.\d+/, " · $1 Hz") }))
                        current: mon.c.mode
                        onPicked: v => page.apply(mon.modelData.name, { mode: v })
                    }
                }
                SettingsRow {
                    visible: !mon.c.disabled
                    title: "Scale"
                    description: "Makes text and windows bigger on sharp screens"
                    Choice {
                        options: [1, 1.25, 1.5, 1.75, 2].map(s => ({ value: s, label: Math.round(s * 100) + "%" }))
                        current: mon.c.scale
                        onPicked: v => page.apply(mon.modelData.name, { scale: v })
                    }
                }
                SettingsRow {
                    visible: !mon.c.disabled
                    title: "Rotation"
                    Choice {
                        options: [{ value: 0, label: "Normal" }, { value: 1, label: "90°" }, { value: 2, label: "180°" }, { value: 3, label: "270°" }]
                        current: mon.c.transform
                        onPicked: v => page.apply(mon.modelData.name, { transform: v })
                    }
                }
            }
        }
    }

    SettingsBox {
        SettingsRow {
            visible: System.brightness >= 0
            title: "Brightness"
            SettingsSlider {
                value: Math.round(System.brightness * 100)
                min: 5
                max: 100
                step: 5
                unit: "%"
                onPicked: v => System.setBrightness(v / 100)
            }
        }
        SettingsRow {
            title: "Night Light"
            description: "Warmer colors that are easier on the eyes in the evening"
            Switch {
                checked: Config.nightLight
                onToggled: Config.toggle("night_light")
            }
        }
        SettingsRow {
            visible: Config.nightLight
            title: "Warmth"
            SettingsSlider {
                value: Config.nightLightTemp
                min: 2500
                max: 6000
                step: 250
                format: v => v + " K"
                onPicked: v => Config.set("night_light_temp", v)
            }
        }
    }
}
