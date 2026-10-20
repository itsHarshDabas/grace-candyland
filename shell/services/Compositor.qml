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
    // Lite mode (set by grace-candyland when drawing on the CPU or with little RAM): blur, shadows and animations off.
    readonly property bool lite: Quickshell.env("GRACE_LITE") === "1"
    property string appliedLayout: "tile"
    // window, fade and workspace speeds in Hyprland units (lower is faster)
    readonly property var speeds: ({ calm: [7, 5, 6], smooth: [4.5, 3, 4], snappy: [2.6, 2, 2.6] })

    function apply() {
        const c = Config;
        const s = speeds[c.animations] || speeds.smooth;
        const g = c.gaps - c.gaps % 2; // gaps_in counts twice between windows, so keep it even
        const kw = [`general:gaps_out ${g}`, `general:gaps_in ${g / 2}`, `decoration:rounding ${c.rounding}`, `decoration:blur:enabled ${c.blur && !lite ? 1 : 0}`, `decoration:shadow:enabled ${lite ? 0 : 1}`, `animations:enabled ${c.animations === "off" || reduceMotion || lite ? 0 : 1}`, `animation windows,1,${s[0]},grace,popin 90%`, `animation fade,1,${s[1]},graceOut`, `animation workspaces,1,${s[2]},grace,slidefade 12%`, `animation layers,1,${s[1]},grace,fade`];
        if (appliedLayout === "float" && c.layout !== "float") {
            // A window rule can't be removed at runtime: reload, and configreloaded re-applies the rest.
            appliedLayout = c.layout;
            Quickshell.execDetached(["hyprctl", "reload"]);
            return;
        }
        if (c.layout === "float")
            kw.push("windowrule float on, match:class .*");
        kw.push(...inputKeywords());
        appliedLayout = c.layout;
        Quickshell.execDetached(["hyprctl", "--batch", kw.map(k => "keyword " + k).join(" ; ")]);
    }

    // Behaviour and input options, only for keys desktop.conf sets (see Config.has).
    function inputKeywords() {
        const c = Config;
        const kw = [];
        const on = b => b ? 1 : 0;
        if (c.has("follow_mouse"))
            kw.push(`input:follow_mouse ${on(c.followMouse)}`);
        if (c.has("tiling"))
            kw.push(`general:layout ${c.tiling === "master" ? "master" : "dwindle"}`);
        if (c.has("snap"))
            kw.push(`general:snap:enabled ${on(c.snap)}`);
        if (c.has("kb_layout") || c.has("layout_switch") || c.has("caps_lock")) {
            const opts = [{ alt_shift: "grp:alt_shift_toggle", ctrl_shift: "grp:ctrl_shift_toggle", caps: "grp:caps_toggle" }[c.layoutSwitch], { escape: "caps:escape", ctrl: "ctrl:nocaps" }[c.capsLock]].filter(o => o);
            kw.push(`input:kb_layout ${c.kbLayout.replace(/[^a-z,]/g, "") || "us"}`, `input:kb_options ${opts.join(",") || "[[EMPTY]]"}`);
        }
        if (c.has("repeat_delay"))
            kw.push(`input:repeat_delay ${c.repeatDelay}`);
        if (c.has("repeat_rate"))
            kw.push(`input:repeat_rate ${c.repeatRate}`);
        if (c.has("pointer_speed"))
            kw.push(`input:sensitivity ${c.pointerSpeed.toFixed(2)}`);
        if (c.has("natural_scroll"))
            kw.push(`input:touchpad:natural_scroll ${on(c.naturalScroll)}`);
        if (c.has("tap_to_click"))
            kw.push(`input:touchpad:tap-to-click ${on(c.tapToClick)}`);
        return kw;
    }

    function setColorScheme() {
        const dark = Config.style !== "light";
        // GTK 3 and Qt apps ignore color-scheme and follow the GTK 3 theme, so switch Adwaita too; any other theme the user picked stays.
        Quickshell.execDetached(["sh", "-c", "command -v gsettings >/dev/null || exit 0; gsettings set org.gnome.desktop.interface color-scheme \"$1\"; case $(gsettings get org.gnome.desktop.interface gtk-theme) in \"'Adwaita'\"|\"'Adwaita-dark'\") gsettings set org.gnome.desktop.interface gtk-theme \"$2\" ;; esac", "sh", dark ? "prefer-dark" : "default", dark ? "Adwaita-dark" : "Adwaita"]);
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
        id: sunset
        command: ["hyprsunset", "-t", String(Config.nightLightTemp)]
        running: Config.nightLight
        // A new temperature needs a restart; hyprsunset reads it only at start.
        onCommandChanged: if (running) {
            running = false;
            Qt.callLater(() => sunset.running = Qt.binding(() => Config.nightLight));
        }
    }

    Component.onCompleted: {
        debounce.restart();
        setColorScheme();
    }
}
