import QtQuick
import qs.config

Rectangle {
    id: root
    property alias icon: glyph.name
    signal clicked

    implicitWidth: 28
    implicitHeight: 28
    radius: 14
    color: mouse.containsMouse ? Theme.controlHover : Theme.control
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    Icon {
        id: glyph
        anchors.centerIn: parent
        size: 14
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
