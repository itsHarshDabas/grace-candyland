import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// Coding agents: what's waiting for approval, recent answers, which agents are installed, and how
// to make an agent ask before it runs a command (grace-approve).
ColumnLayout {
    id: page
    readonly property string description: "Coding agents ask before they run commands on this PC. You answer here or in the control center."
    spacing: 14

    // [command, name, website]
    readonly property var agents: [["claude", "Claude Code", "https://claude.com/claude-code"], ["opencode", "OpenCode", "https://opencode.ai"], ["codex", "Codex CLI", "https://github.com/openai/codex"], ["gemini", "Gemini CLI", "https://github.com/google-gemini/gemini-cli"], ["cline", "Cline", "https://cline.bot"], ["aider", "Aider", "https://aider.chat"]]
    property var found: ({})
    readonly property string example: 'grace-approve "My agent" "npm install express" "$PWD" && npm install express'

    Process {
        command: ["sh", "-c", "for c in \"$@\"; do command -v \"$c\" >/dev/null && echo \"$c\"; done; true", "sh", ...page.agents.map(a => a[0])]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const f = {};
                for (const c of text.split("\n").filter(l => l))
                    f[c] = true;
                page.found = f;
            }
        }
    }

    T {
        text: "Waiting for you"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        SettingsRow {
            visible: Approvals.pending.length === 0
            title: "Nothing is waiting"
            description: "Requests show up here and in the control center until you answer. Nothing is approved on its own."
        }
        Repeater {
            model: Approvals.pending
            Item {
                required property var modelData
                width: parent?.width ?? 0
                implicitHeight: card.implicitHeight + 16
                ApprovalCard {
                    id: card
                    x: 8
                    y: 8
                    width: parent.width - 16
                    request: parent.modelData
                }
            }
        }
    }

    T {
        visible: Approvals.history.length > 0
        text: "Recent answers"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        visible: Approvals.history.length > 0
        Repeater {
            model: Approvals.history
            SettingsRow {
                required property var modelData
                title: modelData.command
                description: `${modelData.agent} · ${Qt.formatDateTime(modelData.time, "HH:mm")}`
                T {
                    text: modelData.allowed ? "Allowed once" : "Denied"
                    color: modelData.allowed ? Theme.success : Theme.error
                    font.pixelSize: 12
                }
            }
        }
    }

    T {
        text: "Coding agents"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        Repeater {
            model: page.agents
            SettingsRow {
                required property var modelData
                title: modelData[1]
                description: page.found[modelData[0]] ? "Installed" : "Not installed"
                titleColor: page.found[modelData[0]] ? "#e9ebf0" : Theme.textSecondary
                Button {
                    text: page.found[modelData[0]] ? "Website" : "Get it"
                    onClicked: Quickshell.execDetached(["xdg-open", modelData[2]])
                }
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Make an agent ask first"
            description: "Put grace-approve in front of a command: it shows the request here and exits 0 only if you allow it. " + page.example
            Button {
                text: "Copy example"
                onClicked: {
                    Quickshell.clipboardText = page.example;
                    text = "Copied";
                }
            }
        }
    }
}
