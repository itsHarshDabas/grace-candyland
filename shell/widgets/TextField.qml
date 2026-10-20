import QtQuick
import qs.config

// A one-line text input. accepted(text) on Enter.
Rectangle {
    id: root
    property alias text: input.text
    property string placeholder
    property bool password: false
    signal accepted(string text)

    implicitWidth: 220
    implicitHeight: 30
    radius: Theme.radiusMd
    color: Theme.control
    border.width: 1
    border.color: input.activeFocus ? Theme.accent.base : "transparent"

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        color: Theme.text
        selectionColor: Theme.accent.fill
        font.family: Theme.font
        font.pixelSize: 13
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        onAccepted: root.accepted(text)
        T {
            anchors.verticalCenter: parent.verticalCenter
            visible: !input.text
            text: root.placeholder
            color: Theme.textTertiary
        }
    }
    function focusInput() {
        input.forceActiveFocus();
    }
}
