import QtQuick
import qs.config

// A 22 px pill in the top bar. `active` brightens it while its panel is open.
Rectangle {
    id: root
    default property alias content: row.data
    property bool active: false
    property bool filled: true
    signal clicked

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 22
    radius: 11
    color: active ? Theme.selected : mouse.containsMouse ? Theme.controlHover : filled ? Theme.control : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
