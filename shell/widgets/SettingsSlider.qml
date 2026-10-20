import QtQuick
import qs.config

// A slider over min..max in steps, with the value and unit shown beside it. picked(n) on change.
Row {
    id: sv
    property real value
    property real min: 0
    property real max: 100
    property real step: 1
    property string unit: ""
    property var format: v => v + sv.unit
    signal picked(real value)
    spacing: 10
    Slider {
        width: 200
        anchors.verticalCenter: parent.verticalCenter
        value: (sv.value - sv.min) / (sv.max - sv.min)
        onMoved: v => {
            const n = Math.round((sv.min + v * (sv.max - sv.min)) / sv.step) * sv.step;
            if (n !== sv.value)
                sv.picked(n);
        }
    }
    T {
        width: 54
        text: sv.format(sv.value)
        color: Theme.textSecondary
        font.pixelSize: 12
    }
}
