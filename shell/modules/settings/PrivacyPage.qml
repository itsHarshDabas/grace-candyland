import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config
import qs.services
import qs.widgets

// Screen lock timing, who is using the microphone or camera right now, recent files, and remote login.
ColumnLayout {
    id: page
    readonly property string description: "Screen lock, microphone and camera use, and what this PC shares."
    spacing: 14

    // Apps recording audio or capturing video right now (PipeWire input streams).
    readonly property var recording: [...Pipewire.nodes.values].filter(n => n.isStream && /^Stream\/Input\/(Audio|Video)/.test(n.properties["media.class"] ?? ""))
    property bool sshOn: false
    property bool cleared: false

    Process {
        id: ssh
        command: ["systemctl", "is-active", "--quiet", "sshd"]
        running: true
        onExited: code => page.sshOn = code === 0
    }
    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: ssh.running = true
    }

    SettingsBox {
        SettingsRow {
            title: "Lock the screen after"
            description: "Without using the mouse or keyboard. Playing videos don't count as idle."
            Choice {
                options: [0, 1, 2, 5, 10, 15, 30, 60].map(m => ({ value: m, label: m === 0 ? "Never" : m === 60 ? "1 h" : `${m} min` }))
                current: Config.lockAfter
                onPicked: v => Config.set("lock_after", v)
            }
        }
        SettingsRow {
            title: "Lock before sleep"
            description: "So the PC wakes up locked"
            Switch {
                checked: Config.lockBeforeSleep
                onToggled: Config.set("lock_before_sleep", Config.lockBeforeSleep ? "off" : "on")
            }
        }
        SettingsRow {
            title: "Lock now"
            description: "Super+L"
            Button {
                text: "Lock"
                onClicked: Ui.lock()
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Microphone and camera"
            description: page.recording.length ? "In use right now by:" : "Nothing is using them right now"
        }
        Repeater {
            model: page.recording
            SettingsRow {
                required property var modelData
                title: modelData.properties["application.name"] || modelData.name
                description: (modelData.properties["media.class"] ?? "").includes("Video") ? "Camera" : "Microphone"
                titleColor: Theme.error
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Recent files"
            description: page.cleared ? "Cleared" : "The list apps show under Recent"
            Button {
                text: "Clear"
                onClicked: {
                    Quickshell.execDetached(["sh", "-c", "rm -f \"${XDG_DATA_HOME:-$HOME/.local/share}/recently-used.xbel\""]);
                    page.cleared = true;
                }
            }
        }
        SettingsRow {
            title: "Local AI"
            description: "CherryCola runs models on this PC. Your questions and files are never sent anywhere by it."
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Remote login (SSH)"
            description: page.sshOn ? "On: anyone with a password for this PC can log in over the network" : "Off"
            Button {
                text: page.sshOn ? "Turn off" : "Turn on"
                // Needs administrator rights: runs in a terminal so you can type your password.
                onClicked: Quickshell.execDetached(["grace-launch", "run", "sudo", "systemctl", page.sshOn ? "disable" : "enable", "--now", "sshd"])
            }
        }
    }
}
