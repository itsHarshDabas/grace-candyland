pragma Singleton
import QtQuick
import Quickshell

// Design tokens from the Grace Shell design (docs/design in the GraceOS repo).
// Neutral dark base; the only color is the accent the user picks.
Singleton {
    // fill: white text on it is >= 4.6:1; fg: readable as text/icons on dark surfaces; tint: wallpaper glow.
    readonly property var accents: ({
            blue: { base: "#3584e4", fill: "#2f75cb", fg: "#4b92e7", tint: "#20324d" },
            teal: { base: "#2190a4", fill: "#1d8092", fg: "#399cae", tint: "#1c3540" },
            green: { base: "#3a944a", fill: "#348442", fg: "#50a05e", tint: "#21362e" },
            yellow: { base: "#c88800", fill: "#9c6a00", fg: "#c88800", tint: "#3e331f" },
            orange: { base: "#ed5b00", fill: "#c74c00", fg: "#ee650f", tint: "#452a1f" },
            red: { base: "#e62d42", fill: "#dd2b3f", fg: "#ec6271", tint: "#44212c" },
            pink: { base: "#d56199", fill: "#b55282", fg: "#d86a9f", tint: "#402b3e" },
            purple: { base: "#9141ac", fill: "#9141ac", fg: "#b27ac5", tint: "#332542" },
            slate: { base: "#6f8396", fill: "#657788", fg: "#8092a3", tint: "#2c323d" }
        })
    readonly property var accentNames: ["blue", "teal", "green", "yellow", "orange", "red", "pink", "purple", "slate"]
    readonly property var accent: accents[Config.accent] || accents.blue

    readonly property color desktop: "#121419"
    readonly property color bar: Config.blur ? Qt.rgba(10 / 255, 11 / 255, 15 / 255, 0.72) : "#0d0e12"
    readonly property color panel: Config.blur ? Qt.rgba(22 / 255, 24 / 255, 31 / 255, 0.82) : "#17191f"
    readonly property color dockBg: Config.blur ? Qt.rgba(18 / 255, 19 / 255, 25 / 255, 0.74) : "#141519"
    readonly property color window: "#1c1e25"
    readonly property color sidebar: "#17191f"
    readonly property color titlebar: "#181a20"

    readonly property color hair: Qt.rgba(1, 1, 1, 0.08)
    readonly property color subtle: Qt.rgba(1, 1, 1, 0.05)
    readonly property color card: Qt.rgba(1, 1, 1, 0.045)
    readonly property color control: Qt.rgba(1, 1, 1, 0.065)
    readonly property color controlStrong: Qt.rgba(1, 1, 1, 0.09)
    readonly property color controlHover: Qt.rgba(1, 1, 1, 0.12)
    readonly property color selected: Qt.rgba(1, 1, 1, 0.14)
    readonly property color track: Qt.rgba(1, 1, 1, 0.12)

    readonly property color textStrong: "#f1f2f6"
    readonly property color text: "#e6e8ee"
    readonly property color textControl: "#d9dce5"
    readonly property color textSecondary: "#8a90a0"
    readonly property color textTertiary: "#7d8392"
    readonly property color success: "#7ed99c"
    readonly property color error: "#ff8a8a"
    readonly property color close: "#ff5f57"
    readonly property color minimize: "#febc2e"
    readonly property color maximize: "#28c840"

    readonly property int gap: Config.gaps
    readonly property int barHeight: 30
    readonly property int panelWidth: 360
    readonly property int radiusSm: 7
    readonly property int radiusMd: 9
    readonly property int radiusLg: 12
    readonly property int radiusXl: 14
    readonly property int radiusPanel: 20

    readonly property string font: "Inter"
    readonly property string mono: "Fira Code"

    // Animation presets scale every shell transition; "off" (or reduce-motion) makes them instant.
    readonly property real motion: ({ off: 0, calm: 1.45, smooth: 1, snappy: 0.65 })[Config.animations] ?? 1
    readonly property int fast: 150 * motion
    readonly property int normal: 240 * motion
    readonly property int slow: 380 * motion
}
