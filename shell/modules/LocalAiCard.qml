import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// "Local AI · on this device": the master AI switch, the running model and the active agent.
// The model row reads `cherrycola status --json` (Ollama or LM Studio); without CherryCola it says nothing is running.
Rectangle {
    id: root
    property bool active
    property string model: ""
    property string backend: ""

    implicitHeight: col.implicitHeight + 24
    radius: Theme.radiusXl
    color: Theme.card

    Timer {
        interval: 5000
        repeat: true
        triggeredOnStart: true
        running: root.active && Config.ai
        onTriggered: ps.running = true
    }
    Process {
        id: ps
        command: ["sh", "-c", "command -v cherrycola >/dev/null && cherrycola status --json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let s = {};
                try {
                    s = JSON.parse(text);
                } catch (e) {}
                root.model = s.running || "";
                root.backend = s.backend || "";
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        RowLayout {
            spacing: 7
            Icon {
                name: "spark"
                size: 14
                color: Config.ai ? Theme.accent.fg : Theme.textTertiary
            }
            T {
                text: "Local AI"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            T {
                Layout.fillWidth: true
                text: Config.ai ? "· on this device" : "· Off"
                color: Theme.textTertiary
                font.pixelSize: 12
            }
            Switch {
                small: true
                checked: Config.ai
                onToggled: Config.toggle("ai")
            }
        }
        RowLayout {
            visible: Config.ai
            spacing: 8
            T {
                Layout.fillWidth: true
                text: root.model ? `${Approvals.esc(root.model)}  <font color="${Theme.textTertiary}">· CherryCola</font>` : "No model running"
                textFormat: Text.StyledText
                color: root.model ? Theme.text : Theme.textTertiary
                font.pixelSize: 12
            }
            Button {
                visible: root.model !== "" && root.backend === "ollama"
                text: "Stop"
                onClicked: Quickshell.execDetached(["ollama", "stop", root.model])
            }
        }
        RowLayout {
            visible: Config.ai
            spacing: 8
            T {
                Layout.fillWidth: true
                readonly property var req: Approvals.current
                text: req ? `${Approvals.esc(req.agent)}  <font color="${Theme.textTertiary}">· waiting for your approval</font>` : "No agent running"
                textFormat: Text.StyledText
                color: req ? Theme.text : Theme.textTertiary
                font.pixelSize: 12
            }
        }
    }
}
