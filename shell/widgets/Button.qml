import QtQuick
import qs.config

// Small pill button. primary = accent fill (Allow once, Open); otherwise a neutral control.
Rectangle {
    id: root
    property alias text: label.text
    property bool primary: false
    signal clicked

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 24
    radius: height / 2
    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent.fill, 1.12) : Theme.accent.fill)
                   : (mouse.containsMouse ? Theme.controlHover : Theme.controlStrong)
    Behavior on color { ColorAnimation { duration: Theme.fast } }

    T {
        id: label
        anchors.centerIn: parent
        color: root.primary ? "white" : Theme.text
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
