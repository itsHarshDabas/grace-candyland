import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.config
import qs.widgets

// Bluetooth through BlueZ (Quickshell.Bluetooth): on/off, discovery while the page is open,
// pair, connect, disconnect and forget.
ColumnLayout {
    id: page
    readonly property string description: "Pair headphones, keyboards, mice and phones."
    spacing: 14

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? [...adapter.devices.values] : []
    readonly property var paired: devices.filter(d => d.paired).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var nearby: devices.filter(d => !d.paired && d.name && d.name !== d.address)

    // Look for new devices, and let phones find this PC, while this page is open.
    Binding {
        when: page.adapter !== null
        target: page.adapter
        property: "discovering"
        value: page.adapter?.enabled ?? false
    }
    Binding {
        when: page.adapter !== null
        target: page.adapter
        property: "discoverable"
        value: page.adapter?.enabled ?? false
    }

    SettingsBox {
        SettingsRow {
            title: "Bluetooth"
            description: !page.adapter ? "No Bluetooth adapter found" : page.adapter.state === BluetoothAdapterState.Blocked ? "Blocked by airplane mode or a hardware switch" : page.adapter.enabled ? `Visible as “${page.adapter.name}” while this page is open` : ""
            Switch {
                visible: page.adapter !== null
                checked: page.adapter?.enabled ?? false
                onToggled: page.adapter.enabled = !page.adapter.enabled
            }
        }
    }

    T {
        visible: page.paired.length > 0 && (page.adapter?.enabled ?? false)
        text: "My devices"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        visible: page.paired.length > 0 && (page.adapter?.enabled ?? false)
        Repeater {
            model: page.paired
            SettingsRow {
                required property var modelData
                title: modelData.name
                description: [modelData.state === BluetoothDeviceState.Connecting ? "Connecting…" : modelData.connected ? "Connected" : "Not connected", modelData.batteryAvailable ? `Battery ${Math.round(modelData.battery * 100)}%` : ""].filter(s => s).join(" · ")
                titleColor: modelData.connected ? Theme.accent.fg : "#e9ebf0"
                Row {
                    spacing: 6
                    Button {
                        text: "Forget"
                        onClicked: modelData.forget()
                    }
                    Button {
                        text: modelData.connected ? "Disconnect" : "Connect"
                        primary: !modelData.connected
                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                    }
                }
            }
        }
    }

    T {
        visible: page.adapter?.enabled ?? false
        text: "Nearby devices"
        color: Theme.textSecondary
        font.pixelSize: 12
        font.weight: Font.Medium
    }
    SettingsBox {
        visible: page.adapter?.enabled ?? false
        SettingsRow {
            visible: page.nearby.length === 0
            title: "Looking for devices…"
            description: "Put the device in pairing mode"
        }
        Repeater {
            model: page.nearby
            SettingsRow {
                required property var modelData
                title: modelData.name
                description: modelData.pairing ? "Pairing… confirm on the device if it asks" : ""
                Button {
                    text: modelData.pairing ? "Cancel" : "Pair"
                    primary: !modelData.pairing
                    onClicked: {
                        if (modelData.pairing) {
                            modelData.cancelPair();
                        } else {
                            modelData.trusted = true; // reconnect automatically later
                            modelData.pair();
                        }
                    }
                }
            }
        }
    }
}
