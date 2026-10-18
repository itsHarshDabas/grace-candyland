import QtQuick
import qs.config

// 6 px track with an accent fill and a white knob. value is 0..1; moved(v) fires while dragging.
Item {
    id: root
    property real value
    signal moved(real value)

    implicitHeight: 16
    opacity: enabled ? 1 : 0.4

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.track
        Rectangle {
            width: Math.max(height, track.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: 3
            color: Theme.accent.fill
        }
    }
    Rectangle {
        width: 14
        height: 14
        radius: 7
        color: "white"
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(1, root.value)) * (root.width - width)
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        function update(x) { root.moved(Math.max(0, Math.min(1, (x - 4) / root.width))); }
        onPressed: e => update(e.x)
        onPositionChanged: e => { if (pressed) update(e.x); }
    }
}
