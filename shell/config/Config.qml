pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ~/.config/grace/desktop.conf: "key = value" lines and "#" comments.
// Settings rewrites only the value it changes, so comments and order survive hand edits.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/grace"
    readonly property string path: dir + "/desktop.conf"
    property var values: ({})

    readonly property string style: get("style", "dark")
    readonly property string accent: get("accent", "blue")
    readonly property int gaps: clamp(parseInt(get("gaps", "10")), 0, 24)
    readonly property int rounding: clamp(parseInt(get("rounding", "12")), 0, 22)
    readonly property bool blur: get("blur", "on") === "on"
    readonly property string layout: get("layout", "tile")
    readonly property string animations: get("animations", "smooth")
    readonly property string dock: get("dock", "hover")
    readonly property bool ai: get("ai", "on") === "on"
    readonly property bool dnd: get("dnd", "off") === "on"
    readonly property bool nightLight: get("night_light", "off") === "on"
    readonly property list<string> pinned: get("pinned", "").split(/\s+/).filter(s => s)
    readonly property string askCommand: get("ask_command", "cherrycola ask")
    // Windows & Workspaces
    readonly property bool followMouse: get("follow_mouse", "on") === "on"
    readonly property string tiling: get("tiling", "dwindle")
    readonly property bool snap: get("snap", "on") === "on"
    // Keyboard, mouse and touchpad
    readonly property string kbLayout: get("kb_layout", "us")
    readonly property string layoutSwitch: get("layout_switch", "alt_shift")
    readonly property string capsLock: get("caps_lock", "caps")
    readonly property int repeatDelay: clamp(parseInt(get("repeat_delay", "600")), 150, 1000)
    readonly property int repeatRate: clamp(parseInt(get("repeat_rate", "25")), 10, 60)
    readonly property real pointerSpeed: Math.max(-1, Math.min(1, parseFloat(get("pointer_speed", "0")) || 0))
    readonly property bool naturalScroll: get("natural_scroll", "on") === "on"
    readonly property bool tapToClick: get("tap_to_click", "on") === "on"
    // Power and screen lock, in minutes (0 = never)
    readonly property int lockAfter: clamp(parseInt(get("lock_after", "10")), 0, 240)
    readonly property int screenOffAfter: clamp(parseInt(get("screen_off_after", "15")), 0, 240)
    readonly property int suspendAfter: clamp(parseInt(get("suspend_after", "0")), 0, 480)
    readonly property bool lockBeforeSleep: get("lock_before_sleep", "on") === "on"
    readonly property int nightLightTemp: clamp(parseInt(get("night_light_temp", "4500")), 2500, 6000)

    // Whether desktop.conf sets this key; input options are only pushed to Hyprland when it does,
    // so settings made in ~/.config/grace/hyprland.conf keep working.
    function has(key) {
        return values[key] !== undefined && values[key] !== "";
    }

    function get(key, fallback) {
        const v = values[key];
        return v === undefined || v === "" ? fallback : v;
    }

    function clamp(v, lo, hi) {
        return isNaN(v) ? lo : Math.max(lo, Math.min(hi, v));
    }

    function parse(text) {
        const out = {};
        for (const line of text.split("\n")) {
            const m = line.match(/^\s*([a-z_]+)\s*=\s*(.*?)\s*(#.*)?$/);
            if (m)
                out[m[1]] = m[2];
        }
        values = out;
    }

    function set(key, value) {
        value = String(value);
        if (values[key] === value)
            return;
        const lines = file.ready ? file.text().split("\n") : [];
        const at = lines.findIndex(l => (l.match(/^\s*([a-z_]+)\s*=/) || [])[1] === key);
        if (at >= 0) {
            const m = lines[at].match(/^(\s*[a-z_]+\s*=\s*)(.*?)(\s*#.*)?$/);
            lines[at] = m[1] + value + (m[3] || "");
        } else {
            if (lines.length && lines[lines.length - 1] === "")
                lines.pop();
            lines.push(`${key} = ${value}`, "");
        }
        const text = lines.join("\n");
        file.setText(text);
        parse(text);
    }

    function toggle(key) {
        set(key, get(key, "off") === "on" ? "off" : "on");
    }

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", dir])

    FileView {
        id: file
        property bool ready: false
        path: root.path
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            ready = true;
            root.parse(text());
        }
    }
}
