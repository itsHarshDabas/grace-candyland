import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.widgets

// Local AI through CherryCola (`cherrycola status --json`, `use`, `backend`, `start`/`stop`; downloads
// run `cherrycola pull` in a terminal so you see the progress).
ColumnLayout {
    id: page
    readonly property string description: "CherryCola runs language models on this PC, through Ollama or LM Studio. Nothing you ask leaves this device."
    spacing: 14

    property var s: ({})          // last `cherrycola status --json`
    property bool installed: true // false when the cherrycola command is missing
    property string busy: ""

    Process {
        id: status
        command: ["sh", "-c", "command -v cherrycola >/dev/null || exit 127; cherrycola status --json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.s = JSON.parse(text);
                } catch (e) {}
            }
        }
        onExited: code => {
            page.installed = code !== 127;
            page.busy = "";
        }
    }
    Timer {
        interval: 4000
        repeat: true
        running: true
        onTriggered: status.running = true
    }
    // What suits this PC (`cherrycola recommend --json`), read once.
    property var rec: ({})
    Process {
        running: true
        command: ["sh", "-c", "command -v cherrycola >/dev/null && cherrycola recommend --json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    page.rec = JSON.parse(text);
                } catch (e) {}
            }
        }
    }
    // Run a cherrycola command, then refresh.
    Process {
        id: action
        onExited: status.running = true
    }
    function run(args, what) {
        busy = what;
        action.command = ["cherrycola", ...args];
        action.running = true;
    }

    SettingsBox {
        SettingsRow {
            title: "Local AI"
            description: "Ask Grace answers, the Local AI card, and agent features. Off hides them all."
            Switch {
                checked: Config.ai
                onToggled: Config.toggle("ai")
            }
        }
    }

    SettingsBox {
        visible: !page.installed
        SettingsRow {
            title: "CherryCola isn't installed"
            description: "Install the cherrycola package (from the GraceOS repo) to run models locally"
            Button {
                text: "Install"
                primary: true
                onClicked: Quickshell.execDetached(["grace-launch", "run", "sudo", "pacman", "-S", "cherrycola", "ollama"])
            }
        }
    }

    SettingsBox {
        visible: page.installed
        SettingsRow {
            title: "Engine"
            description: page.s.backend === "lmstudio" ? "LM Studio's local server must be running (start it in the LM Studio app)" : "Ollama starts when you ask something and runs on this PC"
            Choice {
                options: [{ value: "auto", label: "Automatic" }, { value: "ollama", label: "Ollama" }, { value: "lmstudio", label: "LM Studio" }]
                current: page.s.configured_backend ?? "auto"
                placeholder: page.s.backend === "lmstudio" ? "LM Studio" : "Ollama"
                onPicked: v => page.run(["backend", v], "engine")
            }
        }
        SettingsRow {
            title: "Server"
            description: page.busy === "server" ? "Working…" : page.s.reachable ? "Running" + (page.s.running ? ` · ${page.s.running} loaded in memory` : "") : "Not running"
            Button {
                visible: page.s.backend === "ollama"
                text: page.s.reachable ? "Stop" : "Start"
                onClicked: page.run([page.s.reachable ? "stop" : "start"], "server")
            }
        }
        SettingsRow {
            title: "Model"
            description: page.s.installed === false ? `${page.s.model} isn't downloaded yet` : "Used by Ask Grace and cherrycola ask"
            Row {
                spacing: 6
                Choice {
                    visible: (page.s.models ?? []).length > 0
                    options: (page.s.models ?? []).map(m => ({ value: m, label: m }))
                    current: page.s.model
                    onPicked: v => page.run(["use", v], "model")
                }
                Button {
                    visible: page.s.installed === false && page.s.backend === "ollama"
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Download"
                    primary: true
                    onClicked: Quickshell.execDetached(["grace-launch", "run", "cherrycola", "pull", page.s.model])
                }
            }
        }
    }

    SettingsBox {
        visible: page.installed && !!page.rec.recommended
        SettingsRow {
            readonly property bool have: (page.s.models ?? []).includes(page.rec.recommended)
            title: "Suggested for this PC"
            description: `${page.rec.recommended} runs well on this ${page.rec.runs_on === "gpu" ? "graphics card" : "processor"}`
            Button {
                visible: page.rec.recommended !== page.s.model || !parent.have
                text: parent.have ? "Use" : "Download"
                onClicked: parent.have ? page.run(["use", page.rec.recommended], "model") : Quickshell.execDetached(["grace-launch", "run", "cherrycola", "pull", page.rec.recommended])
            }
        }
        SettingsRow {
            visible: !!page.rec.engine && page.rec.engine !== "ollama"
            title: "Use the graphics card"
            description: page.rec.engine_installed ? `${page.rec.engine} is installed` : `${page.rec.engine_reason}. Installs ${page.rec.engine}.`
            Button {
                visible: !page.rec.engine_installed
                text: "Install"
                onClicked: Quickshell.execDetached(["grace-launch", "run", "sudo", "pacman", "-S", "--needed", page.rec.engine])
            }
        }
    }

    T {
        visible: page.installed && page.s.backend === "ollama"
        text: "Downloaded models"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        visible: page.installed && page.s.backend === "ollama"
        SettingsRow {
            visible: !page.s.reachable
            title: "Start the server to see your models"
        }
        SettingsRow {
            visible: !!page.s.reachable && (page.s.models ?? []).length === 0
            title: "No models yet"
        }
        Repeater {
            model: page.s.reachable ? page.s.models ?? [] : []
            SettingsRow {
                required property string modelData
                title: modelData
                titleColor: modelData === page.s.model ? Theme.accent.fg : "#e9ebf0"
                description: modelData === page.s.model ? "In use" : ""
                Button {
                    text: "Remove"
                    onClicked: page.run(["remove", modelData], "remove")
                }
            }
        }
        SettingsRow {
            title: "Get another model"
            description: "Any name from ollama.com/library, like qwen3:4b or gemma3:4b"
            Row {
                spacing: 6
                TextField {
                    id: newModel
                    width: 180
                    placeholder: "qwen3:4b"
                    onAccepted: get.clicked()
                }
                Button {
                    id: get
                    text: "Download"
                    onClicked: {
                        if (newModel.text.trim())
                            Quickshell.execDetached(["grace-launch", "run", "cherrycola", "pull", newModel.text.trim()]);
                        newModel.text = "";
                    }
                }
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Edit CherryCola settings"
            description: "~/.config/grace/cherrycola.conf (server addresses, default model)"
            link: true
            onActivated: Quickshell.execDetached(["grace-launch", "editor", Config.dir + "/cherrycola.conf"])
        }
    }
}
