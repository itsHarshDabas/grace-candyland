import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.services
import qs.widgets

// "Local AI · on this device": the master AI switch, the running model and the active agent.
// The model row reads `ollama ps` when Ollama is installed; otherwise it says nothing is running.
Rectangle {
    id: root
    property bool active
    property string model: ""
    property string modelSize: ""

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
        command: ["sh", "-c", "command -v ollama >/dev/null && ollama ps 2>/dev/null | sed -n 2p"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(/\s{2,}/);
                root.model = f[0] || "";
                root.modelSize = f[2] || "";
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
                text: root.model ? `${root.model}  <font color="${Theme.textTertiary}">· ${root.modelSize}</font>` : "No model running"
                textFormat: Text.StyledText
                color: root.model ? Theme.text : Theme.textTertiary
                font.pixelSize: 12
            }
            Button {
                visible: root.model !== ""
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
                text: req ? `${req.agent}  <font color="${Theme.textTertiary}">· waiting for your approval</font>` : "No agent running"
                textFormat: Text.StyledText
                color: req ? Theme.text : Theme.textTertiary
                font.pixelSize: 12
            }
        }
    }
}
