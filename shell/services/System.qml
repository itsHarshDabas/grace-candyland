pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

// Status for the tray and the control center. Anything this machine lacks reads as unavailable.
Singleton {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property real batteryLevel: hasBattery ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : 0
    readonly property string batteryPercent: Math.round(batteryLevel * 100) + "%"
    readonly property string batteryText: {
        if (!hasBattery)
            return "";
        const s = UPower.onBattery ? battery.timeToEmpty : 0;
        return s > 0 ? `${batteryPercent} · ${Math.floor(s / 3600)} h ${Math.floor(s % 3600 / 60)} min left` : batteryPercent;
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: !!sink?.audio
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    function setVolume(v) {
        if (!hasAudio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = v;
    }
    function toggleMute() {
        if (hasAudio)
            sink.audio.muted = !sink.audio.muted;
    }

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property string wifiName: {
        for (const d of Networking.devices.values)
            if (d.type === DeviceType.Wifi)
                for (const n of d.networks.values)
                    if (n.connected)
                        return n.name;
        return "";
    }
    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool hasBt: !!adapter
    readonly property bool btOn: adapter?.enabled ?? false
    readonly property string btDevice: [...Bluetooth.devices.values].find(d => d.connected)?.name ?? ""
    function toggleBt() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    readonly property string profileName: ({ [PowerProfile.PowerSaver]: "Power Saver", [PowerProfile.Balanced]: "Balanced", [PowerProfile.Performance]: "Performance" })[PowerProfiles.profile] ?? "Balanced"
    function cycleProfile() {
        const p = PowerProfiles.profile;
        PowerProfiles.profile = p === PowerProfile.Balanced ? (PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver) : p === PowerProfile.Performance ? PowerProfile.PowerSaver : PowerProfile.Balanced;
    }

    property real brightness: -1 // -1: no backlight on this machine
    function setBrightness(v) {
        brightness = v;
        Quickshell.execDetached(["brightnessctl", "-q", "-c", "backlight", "set", Math.max(1, Math.round(v * 100)) + "%"]);
    }
    function refresh() {
        brightnessProc.running = true;
    }
    Process {
        id: brightnessProc
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = text.split(",")[3];
                root.brightness = pct ? parseInt(pct) / 100 : -1;
            }
        }
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
