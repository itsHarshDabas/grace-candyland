import QtQuick
import qs.config

Rectangle {
    id: root
    property bool checked
    property bool small: false
    signal toggled

    implicitWidth: small ? 30 : 40
    implicitHeight: small ? 17 : 22
    radius: height / 2
    color: checked ? Theme.accent.fill : Theme.track
    Behavior on color { ColorAnimation { duration: Theme.normal } }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: "white"
        Behavior on x { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
