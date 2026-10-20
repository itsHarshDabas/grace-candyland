import QtQuick
import QtQuick.Layouts

// A rounded group of SettingsRows.
Rectangle {
    default property alias rows: rowsCol.data
    Layout.fillWidth: true
    implicitHeight: rowsCol.implicitHeight
    radius: 12
    color: Qt.rgba(1, 1, 1, 0.035)
    border.color: Qt.rgba(1, 1, 1, 0.06)
    Column {
        id: rowsCol
        width: parent.width
    }
}
