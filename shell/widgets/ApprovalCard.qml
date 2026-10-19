import QtQuick
import Quickshell
import qs.config
import qs.services

// "Claude Code wants to run `npm install express` in ~/graceos" with Allow once, Deny and Details.
// No keyboard shortcut answers it: a stray key press must never approve a command.
Rectangle {
    id: root
    required property var request
    property bool floating: false
    property bool expanded: false

    implicitHeight: col.implicitHeight + 24
    radius: Theme.radiusXl
    color: floating ? Theme.panel : Theme.card
    border.color: floating ? Theme.hair : "transparent"

    readonly property string home: Quickshell.env("HOME")
    readonly property string cwd: request.cwd.startsWith(home) ? "~" + request.cwd.slice(home.length) : request.cwd

    Column {
        id: col
        anchors.fill: parent
        anchors.margins: 12
        anchors.leftMargin: 14
        spacing: 8

        Row {
            spacing: 8
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "spark"
                size: 14
                color: Theme.accent.fg
            }
            T {
                text: `${root.request.agent} wants to run`
                color: Theme.textStrong
                font.weight: Font.DemiBold
            }
        }
        Row {
            width: parent.width
            spacing: 6
            visible: !root.expanded
            T {
                id: cmd
                width: Math.min(implicitWidth, parent.width - where.implicitWidth - 6)
                text: root.request.command
                font.family: Theme.mono
                font.pixelSize: 12
                color: Theme.text
            }
            T {
                id: where
                text: "in " + root.cwd
                color: Theme.textTertiary
                font.pixelSize: 12
            }
        }
        Rectangle {
            visible: root.expanded
            width: parent.width
            height: full.implicitHeight + 16
            radius: Theme.radiusMd
            color: Theme.control
            T {
                id: full
                anchors.fill: parent
                anchors.margins: 8
                text: root.request.command
                textFormat: Text.PlainText
                font.family: Theme.mono
                font.pixelSize: 12
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideNone
            }
        }
        Column {
            visible: root.expanded
            spacing: 2
            T {
                text: "Working directory: " + root.request.cwd
                color: Theme.textSecondary
                font.pixelSize: 12
            }
            T {
                text: "Requested by: " + root.request.agent
                color: Theme.textSecondary
                font.pixelSize: 12
            }
        }
        Row {
            spacing: 6
            Button {
                text: "Allow once"
                primary: true
                enabled: root.expanded || !cmd.truncated
                opacity: enabled ? 1 : 0.4
                onClicked: Approvals.answer(root.request, true)
            }
            Button {
                text: "Deny"
                onClicked: Approvals.answer(root.request, false)
            }
            Button {
                text: root.expanded ? "Hide details" : "Details"
                onClicked: root.expanded = !root.expanded
            }
        }
    }
}
