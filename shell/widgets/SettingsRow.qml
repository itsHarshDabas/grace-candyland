import QtQuick
import qs.config

// A settings row: title and description on the left, the control on the right. When the row is
// too narrow for both, the control goes under the text. Rows after the first get a hairline on top.
// link: the whole row is a button with a chevron.
Item {
    id: r
    property string title
    property string description
    property bool link: false
    property color titleColor: "#e9ebf0"
    default property alias control: slot.data
    signal activated

    readonly property real controlWidth: slot.childrenRect.width
    readonly property bool stacked: controlWidth > 0 && controlWidth > (width - (link ? 36 : 0)) * 0.5
    readonly property real textWidth: stacked ? width - 28 : width - controlWidth - (link ? 40 : 0) - 44

    width: parent?.width ?? 0
    implicitHeight: stacked ? textCol.implicitHeight + slot.childrenRect.height + 34 : Math.max(textCol.implicitHeight, slot.childrenRect.height) + 24

    Rectangle {
        visible: r.parent && r.parent.children[0] !== r
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.05)
    }
    Column {
        id: textCol
        x: 14
        y: r.stacked ? 12 : (r.height - height) / 2
        width: r.textWidth
        spacing: 2
        T {
            width: parent.width
            text: r.title
            color: r.titleColor
        }
        T {
            width: parent.width
            visible: r.description !== ""
            text: r.description
            color: "#7f8595"
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: slot
        x: r.stacked ? 14 : r.width - width - (r.link ? 36 : 14)
        y: r.stacked ? textCol.y + textCol.height + 10 : (r.height - height) / 2
        width: childrenRect.width
        height: childrenRect.height
    }
    Icon {
        visible: r.link
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        name: "chevronright"
        color: Theme.textSecondary
    }
    MouseArea {
        visible: r.link
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: r.activated()
    }
}
