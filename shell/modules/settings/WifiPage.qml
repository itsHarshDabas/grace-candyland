import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.config
import qs.widgets

// Wi-Fi through NetworkManager (Quickshell.Networking): on/off, scan, connect (with a password
// for secured networks), disconnect and forget.
ColumnLayout {
    id: page
    readonly property string description: "Connect to wireless networks. Wired connections are used automatically."
    spacing: 14

    readonly property var wifi: [...Networking.devices.values].find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var networks: wifi ? [...wifi.networks.values].filter(n => n.name).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)) : []
    readonly property var wired: [...Networking.devices.values].filter(d => d.type === DeviceType.Wired)
    property string asking: ""   // network waiting for a password
    property string failed: ""   // why the last connection failed

    // Scan while this page is open.
    Binding {
        when: page.wifi !== null
        target: page.wifi
        property: "scannerEnabled"
        value: Networking.wifiEnabled
    }

    SettingsBox {
        SettingsRow {
            title: "Wi-Fi"
            description: !Networking.wifiHardwareEnabled ? "Turned off by a hardware switch or airplane mode" : page.wifi ? "" : "No Wi-Fi adapter found"
            Switch {
                visible: page.wifi !== null
                checked: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
        }
        Repeater {
            model: page.wired
            SettingsRow {
                required property var modelData
                title: "Wired (" + modelData.name + ")"
                description: modelData.connected ? "Connected" : "Not connected"
            }
        }
    }

    SettingsBox {
        visible: page.wifi !== null && Networking.wifiEnabled
        SettingsRow {
            visible: page.networks.length === 0
            title: "Looking for networks…"
        }
        Repeater {
            model: page.networks
            Item {
                id: net
                required property var modelData
                readonly property bool secured: modelData.security !== WifiSecurityType.Open
                width: parent?.width ?? 0
                implicitHeight: col.implicitHeight

                Connections {
                    target: net.modelData
                    function onConnectionFailed(reason) {
                        page.failed = net.modelData.name + ": " + ConnectionFailReason.toString(reason);
                        if (net.secured && !net.modelData.known)
                            page.asking = net.modelData.name;
                    }
                }

                Column {
                    id: col
                    width: parent.width
                    SettingsRow {
                        title: net.modelData.name
                        description: [net.modelData.connected ? "Connected" : net.modelData.stateChanging ? "Connecting…" : net.modelData.known ? "Saved" : "", net.secured ? "Secured" : "Open", Math.round(net.modelData.signalStrength * 100) + "% signal"].filter(s => s).join(" · ")
                        titleColor: net.modelData.connected ? Theme.accent.fg : "#e9ebf0"
                        Row {
                            spacing: 6
                            Button {
                                visible: net.modelData.known && !net.modelData.connected
                                text: "Forget"
                                onClicked: net.modelData.forget()
                            }
                            Button {
                                text: net.modelData.connected ? "Disconnect" : "Connect"
                                primary: !net.modelData.connected
                                onClicked: {
                                    page.failed = "";
                                    if (net.modelData.connected)
                                        net.modelData.disconnect();
                                    else if (net.secured && !net.modelData.known)
                                        page.asking = net.modelData.name;
                                    else
                                        net.modelData.connect();
                                }
                            }
                        }
                    }
                    SettingsRow {
                        visible: page.asking === net.modelData.name
                        title: "Password"
                        Row {
                            spacing: 6
                            TextField {
                                id: psk
                                password: true
                                placeholder: "Network password"
                                onAccepted: join.clicked()
                                onVisibleChanged: if (visible) focusInput()
                            }
                            Button {
                                id: join
                                text: "Join"
                                primary: true
                                onClicked: {
                                    net.modelData.connectWithPsk(psk.text);
                                    psk.text = "";
                                    page.asking = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    T {
        visible: page.failed !== ""
        Layout.fillWidth: true
        text: "Couldn't connect to " + page.failed
        color: Theme.error
        wrapMode: Text.Wrap
    }

    SettingsBox {
        SettingsRow {
            title: "Advanced network settings"
            description: "VPNs, hidden networks, static IP addresses and proxies (nmtui)"
            link: true
            onActivated: Quickshell.execDetached(["grace-launch", "run", "nmtui"])
        }
    }
}
