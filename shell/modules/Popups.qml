import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services
import qs.widgets

// Top-right stack under the bar, on the gap grid: a pending approval first (it stays until answered),
// then notification banners for about five seconds. Hidden while the control center is open.
PanelWindow {
    id: win
    required property var bar
    readonly property bool shown: !Ui.ccOpen && Ui.onScreen(bar.screen) && (Approvals.current !== null || Notifs.banners.length > 0)

    visible: shown
    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.gap
        right: Theme.gap
    }
    exclusiveZone: 0
    implicitWidth: Theme.panelWidth
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "grace-popup"

    Column {
        id: stack
        width: parent.width
        spacing: 8

        ApprovalCard {
            width: parent.width
            visible: Approvals.current !== null
            request: Approvals.current ?? { agent: "", command: "", cwd: "", reply: "" }
            floating: true
            Text {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                visible: Approvals.pending.length > 1
                text: `+${Approvals.pending.length - 1} more waiting`
                color: Theme.textTertiary
                font.family: Theme.font
                font.pixelSize: 11
            }
        }

        Repeater {
            model: Notifs.banners
            NotificationCard {
                id: card
                required property var modelData
                width: stack.width
                notification: modelData
                banner: true
                onDone: Notifs.hideBanner(modelData)

                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { NumberAnimation { duration: Theme.normal } }

                Timer {
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                    running: !hover.hovered
                    onTriggered: Notifs.hideBanner(card.modelData)
                }
                HoverHandler { id: hover }
                Connections {
                    target: card.modelData
                    function onClosed() {
                        Notifs.hideBanner(card.modelData);
                    }
                }
            }
        }
    }
}
