import QtQuick
import qs.config

// macOS-style window controls; the glyphs appear on hover.
Row {
    id: root
    signal close
    signal minimize
    signal maximize
    spacing: 7

    Repeater {
        model: [
            { c: Theme.close, g: "x", s: "close" },
            { c: Theme.minimize, g: "", s: "minimize" },
            { c: Theme.maximize, g: "", s: "maximize" }
        ]
        Rectangle {
            required property var modelData
            width: 11
            height: 11
            radius: 5.5
            color: modelData.c
            border.width: 0.5
            border.color: Qt.rgba(0, 0, 0, 0.28)
            Icon {
                anchors.centerIn: parent
                name: parent.modelData.g
                size: 9
                color: Qt.rgba(0, 0, 0, 0.55)
                visible: hover.hovered && name !== ""
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root[parent.modelData.s]()
            }
        }
    }
    HoverHandler { id: hover }
}
