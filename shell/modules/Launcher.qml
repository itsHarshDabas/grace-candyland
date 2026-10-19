import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// "Ask Grace" (Super+Space): app search first. With AI on, the last row hands the question to
// `ask_command` from desktop.conf; without one configured it says so instead of pretending.
PanelWindow {
    id: win
    required property var bar
    readonly property bool open: Ui.launcherOpen && Ui.onScreen(bar.screen)
    property string query: ""
    property int current: 0
    property string note: ""

    readonly property var apps: {
        const q = query.trim().toLowerCase();
        const all = [...DesktopEntries.applications.values].filter(e => !e.noDisplay);
        if (!q)
            return all.sort((a, b) => a.name.localeCompare(b.name)).slice(0, 7);
        const score = e => {
            const n = e.name.toLowerCase();
            if (n.startsWith(q))
                return 3;
            if (n.split(/\s+/).some(w => w.startsWith(q)))
                return 2;
            if ((n + " " + e.genericName + " " + e.keywords + " " + e.comment).toLowerCase().includes(q))
                return 1;
            return 0;
        };
        return all.map(e => ({ e, s: score(e) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name)).slice(0, 7).map(x => x.e);
    }
    readonly property bool askRow: Config.ai && query.trim() !== ""
    readonly property int count: apps.length + (askRow ? 1 : 0)

    visible: open || fade.running
    anchors.top: true
    margins.top: Theme.gap
    exclusiveZone: 0
    implicitWidth: 560
    implicitHeight: box.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "grace-launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    HyprlandFocusGrab {
        windows: [win, win.bar]
        active: win.open
        onCleared: Ui.launcherOpen = false
    }

    onOpenChanged: {
        if (open) {
            query = "";
            note = "";
            current = 0;
            input.forceActiveFocus();
        }
    }
    onQueryChanged: {
        current = 0;
        note = "";
    }

    function activate(i) {
        if (i < apps.length) {
            apps[i].execute();
            Ui.launcherOpen = false;
        } else if (askRow) {
            if (!Config.askCommand) {
                note = "No local model is set up yet. Set ask_command in ~/.config/grace/desktop.conf.";
                return;
            }
            Quickshell.execDetached(["sh", "-c", Config.askCommand + ' "$1"', "sh", query.trim()]);
            Ui.launcherOpen = false;
        }
    }

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: col.implicitHeight + 12
        radius: 16
        color: Theme.panel
        border.color: Theme.hair

        opacity: win.open ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: Theme.fast } }
        transform: Translate {
            y: win.open ? 0 : -8
            Behavior on y { NumberAnimation { duration: Theme.normal; easing.type: Easing.OutCubic } }
        }

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 6

            Item {
                width: parent.width
                height: 44
                Icon {
                    id: lead
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    name: Config.ai ? "spark" : "search"
                    color: Config.ai ? Theme.accent.fg : Theme.textSecondary
                }
                TextInput {
                    id: input
                    anchors.left: lead.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.query
                    onTextEdited: win.query = text
                    color: Theme.textStrong
                    selectionColor: Theme.accent.fill
                    font.family: Theme.font
                    font.pixelSize: 15
                    Keys.onEscapePressed: Ui.launcherOpen = false
                    Keys.onUpPressed: win.current = Math.max(0, win.current - 1)
                    Keys.onDownPressed: win.current = Math.min(win.count - 1, win.current + 1)
                    Keys.onReturnPressed: win.activate(win.current)
                    Keys.onEnterPressed: win.activate(win.current)
                    T {
                        anchors.fill: parent
                        visible: !input.text
                        text: Config.ai ? "Ask Grace or search apps" : "Search apps"
                        color: Theme.textTertiary
                        font.pixelSize: 15
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.subtle
                visible: win.count > 0
            }
            Item {
                width: 1
                height: 4
                visible: win.count > 0
            }
            Repeater {
                model: win.apps
                Row {
                    id: appRow
                    required property var modelData
                    required property int index
                    width: col.width
                    height: 40
                    Rectangle {
                        width: parent.width
                        height: parent.height
                        radius: Theme.radiusMd
                        color: win.current === appRow.index ? Theme.selected : "transparent"
                        IconImage {
                            id: appIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 24
                            source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                        }
                        T {
                            anchors.left: appIcon.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: Approvals.esc(appRow.modelData.name) + (appRow.modelData.genericName ? `  <font color="${Theme.textTertiary}">${Approvals.esc(appRow.modelData.genericName)}</font>` : "")
                            textFormat: Text.StyledText
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: win.current = appRow.index
                            onClicked: win.activate(appRow.index)
                        }
                    }
                }
            }
            Rectangle {
                visible: win.askRow
                width: parent.width
                height: 40
                radius: Theme.radiusMd
                color: win.current === win.apps.length ? Theme.selected : "transparent"
                Icon {
                    id: askIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    name: "spark"
                    color: Theme.accent.fg
                }
                T {
                    anchors.left: askIcon.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: `Ask Grace: “${win.query.trim()}”`
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: win.current = win.apps.length
                    onClicked: win.activate(win.apps.length)
                }
            }
            T {
                visible: win.note !== ""
                width: parent.width
                leftPadding: 14
                rightPadding: 14
                topPadding: 4
                bottomPadding: 6
                text: win.note
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
        }
    }
}
