import QtQuick
import qs.config

Rectangle {
    id: root
    property var options: []      // [{ value, label }]
    property var current
    signal picked(var value)

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 32
    radius: Theme.radiusMd
    color: Theme.control

    Row {
        id: row
        anchors.centerIn: parent
        Repeater {
            model: root.options
            Rectangle {
                required property var modelData
                readonly property bool on: modelData.value === root.current
                width: label.implicitWidth + 24
                height: 26
                radius: Theme.radiusSm
                color: on ? Theme.selected : (mouse.containsMouse ? Theme.control : "transparent")
                Behavior on color { ColorAnimation { duration: Theme.fast } }
                T {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.on ? "white" : Theme.textControl
                    font.pixelSize: 13
                }
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.modelData.value)
                }
            }
        }
    }
}
