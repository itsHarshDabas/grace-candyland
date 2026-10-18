import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

// One notification: app icon tile, summary and body. Click runs the default action; × dismisses.
Rectangle {
    id: root
    required property var notification
    property bool banner: false
    signal done

    implicitHeight: body.implicitHeight + 16
    radius: Theme.radiusXl
    color: banner ? Theme.panel : Theme.card
    border.color: banner ? Theme.hair : "transparent"

    readonly property string iconSource: {
        const n = notification;
        if (n.image)
            return n.image;
        if (n.appIcon.startsWith("/") || n.appIcon.startsWith("file:"))
            return n.appIcon;
        return Quickshell.iconPath(n.appIcon || n.desktopEntry, true);
    }

    Row {
        id: body
        anchors.fill: parent
        anchors.margins: 8
        anchors.leftMargin: 10
        spacing: 9

        Rectangle {
            width: 26
            height: 26
            radius: 8
            color: Theme.controlStrong
            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: root.iconSource
                visible: root.iconSource !== ""
            }
            Icon {
                anchors.centerIn: parent
                visible: root.iconSource === ""
                name: "bell"
                size: 14
            }
        }
        Column {
            width: parent.width - 35
            spacing: 2
            T {
                width: parent.width - 16
                text: root.notification.summary || root.notification.appName
                color: Theme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            T {
                width: parent.width
                visible: text !== ""
                text: root.notification.body
                textFormat: Text.PlainText
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 3
            }
            Row {
                visible: actions.count > 0
                spacing: 6
                topPadding: 4
                Repeater {
                    id: actions
                    model: root.notification.actions.filter(a => a.identifier !== "default")
                    Button {
                        required property var modelData
                        text: modelData.text
                        onClicked: {
                            modelData.invoke();
                            root.done();
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: {
            const def = root.notification.actions.find(a => a.identifier === "default");
            if (def)
                def.invoke();
            root.done();
        }
    }
    Icon {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 8
        name: "x"
        size: 12
        color: Theme.textSecondary
        visible: mouse.containsMouse || closeMouse.containsMouse
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            anchors.margins: -4
            hoverEnabled: true
            onClicked: root.notification.dismiss()
        }
    }
}
