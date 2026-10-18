import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Hidden until the pointer touches the bottom-middle edge (a small handle hints at it).
// Real app icons from the icon theme; a dot marks running apps; a divider sets Settings apart.
PanelWindow {
    id: win
    required property ShellScreen modelData
    screen: modelData

    readonly property bool always: Config.dock === "always"
    property bool hovered: false
    readonly property bool shown: always || hovered

    // Toplevels grouped by app id, so pinned apps can show a running dot and focus their window.
    readonly property var running: {
        const out = {};
        for (const t of Hyprland.toplevels.values) {
            const id = (t.wayland?.appId || t.lastIpcObject?.class || "").toLowerCase();
            if (id && !out[id])
                out[id] = t;
        }
        return out;
    }
    readonly property var items: {
        DesktopEntries.applications.values; // re-run once the app list has loaded
        const seen = new Set();
        const out = [];
        const add = e => {
            if (e && !seen.has(e.id)) {
                seen.add(e.id);
                out.push(e);
            }
        };
        for (const id of Config.pinned)
            if (id !== "grace-settings")
                add(DesktopEntries.byId(id));
        for (const id in running)
            add(DesktopEntries.heuristicLookup(id));
        return out;
    }

    function windowOf(entry) {
        return running[(entry.startupClass || entry.id).toLowerCase()] ?? running[entry.id.toLowerCase()];
    }
    function launch(entry) {
        const t = windowOf(entry);
        if (t)
            Hyprland.dispatch(`focuswindow address:0x${t.address}`);
        else
            entry.execute();
    }

    visible: Config.dock !== "never"
    anchors.bottom: true
    exclusionMode: always ? ExclusionMode.Auto : ExclusionMode.Ignore
    implicitWidth: dock.width + 40
    implicitHeight: dock.height + Theme.gap + 12
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "grace-dock"
    // While hidden only the thin strip at the bottom takes input, so windows above stay clickable.
    mask: Region { item: win.shown ? dock : hotStrip }

    Timer {
        id: hideDelay
        interval: 450
        onTriggered: win.hovered = false
    }
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                hideDelay.stop();
                win.hovered = true;
            } else {
                hideDelay.restart();
            }
        }
    }

    Item {
        id: hotStrip
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: dock.width
        height: 6
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 64
        height: 4
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.26)
        opacity: win.shown ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }
    }

    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        y: win.shown ? win.height - height - Theme.gap : win.height + 4
        Behavior on y { NumberAnimation { duration: Theme.slow; easing.type: Easing.OutBack; easing.overshoot: 0.9 } }
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.normal } }

        width: row.implicitWidth + 14
        height: 54 + 4
        radius: 18
        color: Theme.dockBg
        border.color: Theme.hair

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: win.items
                DockItem {
                    required property var modelData
                    entry: modelData
                    running: !!win.windowOf(modelData)
                    onClicked: win.launch(modelData)
                }
            }
            Rectangle {
                visible: settingsItem.entry !== null
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 32
                color: Theme.track
            }
            DockItem {
                id: settingsItem
                entry: DesktopEntries.applications.values.length ? DesktopEntries.byId("grace-settings") : null
                visible: entry !== null
                running: Ui.settingsOpen
                onClicked: Ui.openSettings()
            }
        }
    }

    component DockItem: Item {
        id: item
        property var entry
        property bool running
        signal clicked

        width: 44
        height: 50
        IconImage {
            anchors.horizontalCenter: parent.horizontalCenter
            y: mouse.containsMouse ? 0 : 4
            Behavior on y { NumberAnimation { duration: Theme.fast; easing.type: Easing.OutCubic } }
            implicitSize: 40
            source: item.entry ? Quickshell.iconPath(item.entry.icon, "application-x-executable") : ""
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            visible: item.running
            width: 4
            height: 4
            radius: 2
            color: "#cfd3dc"
        }
        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: item.clicked()
        }
    }
}
