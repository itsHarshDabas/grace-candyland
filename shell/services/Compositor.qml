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

    // A JS value as a Lua literal: objects become tables, strings are quoted.
    function lua(v) {
        if (typeof v === "string")
            return JSON.stringify(v);
        if (typeof v === "object")
            return "{ " + Object.keys(v).map(k => `${/^[a-z_][a-z0-9_]*$/.test(k) ? k : `[${JSON.stringify(k)}]`} = ${lua(v[k])}`).join(", ") + " }";
        return String(v);
    }

    // Hyprland 0.57 reads only Lua, and `hyprctl keyword` is gone: changes go through `hyprctl eval`.
    function apply() {
        const c = Config;
        const s = speeds[c.animations] || speeds.smooth;
        const g = c.gaps - c.gaps % 2; // gaps_in counts twice between windows, so keep it even
        if (appliedLayout === "float" && c.layout !== "float") {
            // A window rule can't be removed at runtime: reload, and configreloaded re-applies the rest.
            appliedLayout = c.layout;
            Quickshell.execDetached(["hyprctl", "reload"]);
            return;
        }
        const conf = {
            general: { gaps_out: g, gaps_in: g / 2 },
            decoration: { rounding: c.rounding, blur: { enabled: c.blur && !lite }, shadow: { enabled: !lite } },
            animations: { enabled: !(c.animations === "off" || reduceMotion || lite) }
        };
        addInput(conf);
        const code = [`hl.config(${lua(conf)})`, ...[["windows", s[0], "grace", "popin 90%"], ["fade", s[1], "graceOut", ""], ["workspaces", s[2], "grace", "slidefade 12%"], ["layers", s[1], "grace", "fade"]].map(([leaf, speed, bezier, style]) => `hl.animation(${lua(Object.assign({ leaf, enabled: true, speed, bezier }, style ? { style } : {}))})`)];
        if (c.layout === "float")
            code.push(`hl.window_rule(${lua({ name: "grace-float-all", match: { class: ".*" }, float: true })})`);
        appliedLayout = c.layout;
        Quickshell.execDetached(["hyprctl", "eval", code.join("; ")]);
    }

    // Behaviour and input options, only for keys desktop.conf sets (see Config.has).
    function addInput(conf) {
        const c = Config;
        const input = {};
        const touchpad = {};
        if (c.has("follow_mouse"))
            input.follow_mouse = c.followMouse ? 1 : 0;
        if (c.has("tiling"))
            conf.general.layout = c.tiling === "master" ? "master" : "dwindle";
        if (c.has("snap"))
            conf.general.snap = { enabled: c.snap };
        if (c.has("kb_layout") || c.has("layout_switch") || c.has("caps_lock")) {
            const opts = [{ alt_shift: "grp:alt_shift_toggle", ctrl_shift: "grp:ctrl_shift_toggle", caps: "grp:caps_toggle" }[c.layoutSwitch], { escape: "caps:escape", ctrl: "ctrl:nocaps" }[c.capsLock]].filter(o => o);
            input.kb_layout = c.kbLayout.replace(/[^a-z,]/g, "") || "us";
            input.kb_options = opts.join(",");
        }
        if (c.has("repeat_delay"))
            input.repeat_delay = c.repeatDelay;
        if (c.has("repeat_rate"))
            input.repeat_rate = c.repeatRate;
        if (c.has("pointer_speed"))
            input.sensitivity = Number(c.pointerSpeed.toFixed(2));
        if (c.has("natural_scroll"))
            touchpad.natural_scroll = c.naturalScroll;
        if (c.has("tap_to_click"))
            touchpad.tap_to_click = c.tapToClick;
        if (Object.keys(touchpad).length)
            input.touchpad = touchpad;
        if (Object.keys(input).length)
            conf.input = input;
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
