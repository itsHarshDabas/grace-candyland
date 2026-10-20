import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config
import qs.widgets

// PipeWire: pick the output and input device, their volume and mute, and per-app volume.
ColumnLayout {
    id: page
    readonly property string description: "Speakers, headphones and microphones, and how loud each app plays."
    spacing: 14

    readonly property var nodes: [...Pipewire.nodes.values].filter(n => n.audio)
    readonly property var outputs: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.isStream && (n.properties["media.class"] ?? "").startsWith("Stream/Output"))
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // Volume and mute are only live for tracked nodes.
    PwObjectTracker {
        objects: page.nodes
    }

    function label(n) {
        return n.nickname || n.description || n.name;
    }

    SettingsBox {
        SettingsRow {
            title: "Output"
            description: page.outputs.length ? "" : "No speakers or headphones found"
            Choice {
                visible: page.outputs.length > 0
                options: page.outputs.map(n => ({ value: n.id, label: page.label(n) }))
                current: page.sink?.id
                onPicked: v => Pipewire.preferredDefaultAudioSink = page.outputs.find(n => n.id === v)
            }
        }
        SettingsRow {
            visible: !!page.sink?.audio
            title: "Volume"
            Row {
                spacing: 12
                SettingsSlider {
                    value: Math.round((page.sink?.audio?.volume ?? 0) * 100)
                    max: 100
                    step: 2
                    unit: "%"
                    onPicked: v => {
                        page.sink.audio.muted = false;
                        page.sink.audio.volume = v / 100;
                    }
                }
                Button {
                    text: page.sink?.audio?.muted ? "Unmute" : "Mute"
                    onClicked: page.sink.audio.muted = !page.sink.audio.muted
                }
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Input"
            description: page.inputs.length ? "" : "No microphone found"
            Choice {
                visible: page.inputs.length > 0
                options: page.inputs.map(n => ({ value: n.id, label: page.label(n) }))
                current: page.source?.id
                onPicked: v => Pipewire.preferredDefaultAudioSource = page.inputs.find(n => n.id === v)
            }
        }
        SettingsRow {
            visible: !!page.source?.audio
            title: "Input volume"
            Row {
                spacing: 12
                SettingsSlider {
                    value: Math.round((page.source?.audio?.volume ?? 0) * 100)
                    max: 100
                    step: 2
                    unit: "%"
                    onPicked: v => {
                        page.source.audio.muted = false;
                        page.source.audio.volume = v / 100;
                    }
                }
                Button {
                    text: page.source?.audio?.muted ? "Unmute" : "Mute"
                    onClicked: page.source.audio.muted = !page.source.audio.muted
                }
            }
        }
    }

    T {
        text: "Apps"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        SettingsRow {
            visible: page.apps.length === 0
            title: "No app is playing sound"
        }
        Repeater {
            model: page.apps
            SettingsRow {
                required property var modelData
                title: modelData.properties["application.name"] || page.label(modelData)
                description: modelData.properties["media.name"] ?? ""
                SettingsSlider {
                    value: Math.round((modelData.audio?.volume ?? 0) * 100)
                    max: 100
                    step: 2
                    unit: "%"
                    onPicked: v => modelData.audio.volume = v / 100
                }
            }
        }
    }
}
