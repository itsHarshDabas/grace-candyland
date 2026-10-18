import QtQuick
import qs.config

// 48 px pill toggle for the control center: icon, label and an optional subtitle.
Rectangle {
    id: root
    property string icon
    property string label
    property string subtitle
    property bool on
    property bool available: true
    signal clicked

    implicitHeight: 48
    radius: 24
    opacity: available ? 1 : 0.45
    color: on ? (mouse.containsMouse ? Qt.lighter(Theme.accent.fill, 1.1) : Theme.accent.fill) : (mouse.containsMouse ? Theme.controlHover : Theme.control)
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            color: root.on ? "white" : Theme.textControl
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 26
            T {
                width: parent.width
                text: root.label
                color: root.on ? "white" : Theme.textControl
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            T {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                color: root.on ? "white" : Theme.textControl
                opacity: 0.75
                font.pixelSize: 11
            }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
