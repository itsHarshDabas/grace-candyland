import QtQuick
import Quickshell
import qs.config

// A dropdown: shows the current option's label; clicking opens a list below it.
Rectangle {
    id: root
    property var options: []      // [{ value, label }]
    property var current
    property string placeholder: "Choose"
    signal picked(var value)

    readonly property var currentOption: options.find(o => o.value === current)
    implicitWidth: Math.max(160, label.implicitWidth + 44)
    implicitHeight: 30
    radius: Theme.radiusMd
    color: mouse.containsMouse || popup.visible ? Theme.controlHover : Theme.control

    T {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: chevron.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.currentOption?.label ?? root.placeholder
        color: root.currentOption ? Theme.text : Theme.textSecondary
    }
    Icon {
        id: chevron
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        name: "chevrondown"
        size: 12
        color: Theme.textSecondary
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = !popup.visible
    }

    PopupWindow {
        id: popup
        anchor.item: root
        anchor.rect.y: root.height + 4
        implicitWidth: root.width
        implicitHeight: Math.min(list.contentHeight + 8, 260)
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.radiusMd
            color: Theme.panel
            border.color: Theme.hair
            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                model: root.options
                boundsBehavior: Flickable.StopAtBounds
                delegate: Rectangle {
                    required property var modelData
                    width: list.width
                    height: 28
                    radius: Theme.radiusSm
                    color: optMouse.containsMouse ? Theme.controlHover : modelData.value === root.current ? Theme.selected : "transparent"
                    T {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.modelData.label
                    }
                    MouseArea {
                        id: optMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            popup.visible = false;
                            root.picked(parent.modelData.value);
                        }
                    }
                }
            }
        }
    }
}
