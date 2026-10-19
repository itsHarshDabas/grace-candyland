pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Pushes desktop.conf to the running Hyprland, the apps' color scheme and the night light.
Singleton {
    id: root

    property bool reduceMotion: false
    // Hyprland is drawing on the CPU (see grace-candyland): blur, shadows and animations would make it crawl.
    readonly property bool software: Quickshell.env("GRACE_SOFTWARE_RENDERING") === "1"
    property string appliedLayout: "tile"
    // window, fade and workspace speeds in Hyprland units (lower is faster)
    readonly property var speeds: ({ calm: [7, 5, 6], smooth: [4.5, 3, 4], snappy: [2.6, 2, 2.6] })

    function apply() {
        const c = Config;
        const s = speeds[c.animations] || speeds.smooth;
        const g = c.gaps - c.gaps % 2; // gaps_in counts twice between windows, so keep it even
        const kw = [`general:gaps_out ${g}`, `general:gaps_in ${g / 2}`, `decoration:rounding ${c.rounding}`, `decoration:blur:enabled ${c.blur && !software ? 1 : 0}`, `decoration:shadow:enabled ${software ? 0 : 1}`, `animations:enabled ${c.animations === "off" || reduceMotion || software ? 0 : 1}`, `animation windows,1,${s[0]},grace,popin 90%`, `animation fade,1,${s[1]},graceOut`, `animation workspaces,1,${s[2]},grace,slidefade 12%`, `animation layers,1,${s[1]},grace,fade`];
        if (appliedLayout === "float" && c.layout !== "float") {
            // A window rule can't be removed at runtime: reload, and configreloaded re-applies the rest.
            appliedLayout = c.layout;
            Quickshell.execDetached(["hyprctl", "reload"]);
            return;
        }
        if (c.layout === "float")
            kw.push("windowrule float on, match:class .*");
        appliedLayout = c.layout;
        Quickshell.execDetached(["hyprctl", "--batch", kw.map(k => "keyword " + k).join(" ; ")]);
    }

    function setColorScheme() {
        Quickshell.execDetached(["sh", "-c", "command -v gsettings >/dev/null && gsettings set org.gnome.desktop.interface color-scheme \"$1\"", "sh", Config.style === "light" ? "default" : "prefer-dark"]);
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: root.apply()
    }
    Connections {
        target: Config
        function onValuesChanged() {
            debounce.restart();
        }
        function onStyleChanged() {
            root.setColorScheme();
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                debounce.restart();
        }
    }

    // Follow the system reduce-motion setting.
    Process {
        command: ["gsettings", "get", "org.gnome.desktop.interface", "enable-animations"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.reduceMotion = text.trim() === "false"
        }
    }
    Process {
        command: ["hyprsunset", "-t", "4500"]
        running: Config.nightLight
    }

    Component.onCompleted: {
        debounce.restart();
        setColorScheme();
    }
}
