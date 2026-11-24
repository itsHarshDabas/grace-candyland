import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// "Ask Grace" (Super+Space): app search first. With AI on, the last row asks `ask_command` from
// desktop.conf (CherryCola by default) and streams its answer into the panel.
PanelWindow {
    id: win
    required property var bar
    readonly property bool open: Ui.launcherOpen && Ui.onScreen(bar.screen)
    property string query: ""
    property int current: 0
    property string note: ""
    property string answer: ""
    property bool modelMissing: false
    property bool canPull: false // the model is missing and `cherrycola pull` fetches it (Ollama)
    property bool cancelled: false // the running ask was stopped: ignore what it still prints
    property bool follow: true // keep the newest streamed text in view until the user scrolls
    readonly property bool asking: asker.running && !cancelled
    // Several words ending in "?" or starting like a question: Enter should ask, not open an app.
    readonly property bool looksLikeQuestion: /\?\s*$/.test(query) || /^\s*(how|what|why|when|where|who|which|can|could|should|is|are|does|do|explain|tell)\b.*\s\S/i.test(query)

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
            // Descriptions only for 2+ letters: one letter matches nearly every comment.
            if (q.length > 1 && (n + " " + e.genericName + " " + e.keywords + " " + e.comment).toLowerCase().includes(q))
                return 1;
            return 0;
        };
        return all.map(e => ({ e, s: score(e) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name)).slice(0, 7).map(x => x.e);
    }
    readonly property bool askRow: Config.ai && query.trim() !== ""
    readonly property int count: apps.length + (askRow ? 1 : 0)
    readonly property bool noMatches: count === 0 && query.trim() !== ""

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
            answer = "";
            current = 0;
            input.forceActiveFocus();
        } else {
            stopAsking(); // closing the panel doesn't leave the model running
        }
    }
    onQueryChanged: {
        current = askRow && looksLikeQuestion ? apps.length : 0;
        note = "";
        answer = "";
        modelMissing = false;
        canPull = false;
        stopAsking();
    }

    function stopAsking() {
        if (asker.running) {
            cancelled = true; // its exit (killed, so non-zero) must not show up as an error
            asker.running = false;
        }
    }

    // Model output is untrusted Markdown: no raw HTML and no images (they could load files or URLs).
    // Code spans and blocks are left alone, so "<stdio.h>" in code still reads right.
    function safeMarkdown(text) {
        return text.split(/(```[\s\S]*?(?:```|$)|`[^`\n]*`)/).map((part, i) => i % 2 ? part : part.replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1").replace(/<(?=[A-Za-z!\/?])/g, "&lt;")).join("");
    }

    function sentence(text) {
        return text.charAt(0).toUpperCase() + text.slice(1);
    }

    // The ask command gets the question as its last argument and prints the answer to stdout.
    Process {
        id: asker
        stdout: SplitParser {
            splitMarker: "" // every chunk as it arrives, so the answer streams in
            onRead: data => {
                if (!win.cancelled)
                    win.answer += data;
            }
        }
        stderr: StdioCollector {
            id: askErr
        }
        onExited: code => {
            if (win.cancelled) {
                win.cancelled = false;
                return;
            }
            const err = askErr.text.trim().split("\n").filter(l => !/^\(.*\)$/.test(l)).pop() || ""; // skip "(loading …)" status lines
            win.modelMissing = code === 3; // CherryCola: the model isn't downloaded yet
            win.canPull = code === 3 && /\bpull\b/.test(err); // llama.cpp and LM Studio get models another way
            if (code === 127)
                win.note = "CherryCola isn't installed. Install it, or set ask_command in ~/.config/grace/desktop.conf.";
            else if (code !== 0)
                win.note = win.sentence(err.replace(/^CherryCola(LLM)?: /i, "").replace(/\.?\s*Run: cherrycola(llm)? pull\S*$/, ".")) || `The ask command failed (exit ${code}).`;
            // Start reading at the top of a long answer, unless the user already scrolled.
            if (code === 0 && win.follow)
                answerView.contentY = 0;
        }
    }

    function activate(i) {
        if (i < apps.length) {
            apps[i].execute();
            Ui.launcherOpen = false;
        } else if (askRow && !asker.running) {
            answer = "";
            note = "";
            cancelled = false;
            follow = true;
            asker.command = ["sh", "-c", Config.askCommand + ' "$1"', "sh", query.trim()];
            asker.running = true;
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
                    clip: true // long questions scroll inside the field, not under the icon
                    onTextEdited: win.query = text
                    color: Theme.textStrong
                    selectionColor: Theme.accent.fill
                    font.family: Theme.font
                    font.pixelSize: 15
                    // Esc stops a running answer first, then closes.
                    Keys.onEscapePressed: win.asking ? win.stopAsking() : Ui.launcherOpen = false
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
                visible: win.count > 0 || win.noMatches
            }
            Item {
                width: 1
                height: 4
                visible: win.count > 0
            }
            // Nothing matches (only possible with AI off: with AI on the ask row is always there).
            Column {
                visible: win.noMatches
                width: parent.width
                topPadding: 10
                bottomPadding: 10
                spacing: 4
                T {
                    width: parent.width
                    leftPadding: 14
                    rightPadding: 14
                    text: `No apps match “${win.query.trim()}”`
                    color: Theme.textSecondary
                }
                T {
                    visible: !Config.ai
                    width: parent.width
                    leftPadding: 14
                    rightPadding: 14
                    text: "Ask Grace is off. Turn it on in Settings › AI & Models to ask questions here."
                    color: Theme.textTertiary
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Ui.openSettings("AI & Models")
                    }
                }
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
            Flickable {
                id: answerView
                visible: win.answer !== "" || win.asking
                width: parent.width
                height: Math.min(answerText.implicitHeight, 320)
                contentHeight: answerText.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                // Follow the answer while it streams in, until the user scrolls it themselves.
                onMovementStarted: win.follow = false
                onContentHeightChanged: if (win.asking && win.follow) contentY = Math.max(0, contentHeight - height)
                WheelHandler {
                    onWheel: win.follow = false
                }
                TextEdit {
                    id: answerText
                    width: parent.width
                    leftPadding: 14
                    rightPadding: 14
                    topPadding: 8
                    bottomPadding: 8
                    text: win.answer.trim() ? win.safeMarkdown(win.answer.trim()) : "Thinking…"
                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    textFormat: TextEdit.MarkdownText // lists, **bold** and `code` as the model meant them
                    color: win.answer ? Theme.text : Theme.textTertiary
                    selectionColor: Theme.accent.fill
                    font.family: Theme.font
                    font.pixelSize: 14
                }
            }
            Row {
                visible: win.answer.trim() !== "" && !win.asking
                x: 14
                spacing: 8
                bottomPadding: 6
                Button {
                    id: copyButton
                    property bool copied: false
                    text: copied ? "Copied" : "Copy answer"
                    onClicked: {
                        Quickshell.clipboardText = win.answer.trim();
                        copied = true;
                        copiedTimer.restart();
                    }
                    Timer {
                        id: copiedTimer
                        interval: 1500
                        onTriggered: copyButton.copied = false
                    }
                }
                Button {
                    text: "Ask again"
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
            Item {
                visible: win.note !== "" && !win.canPull && win.askRow
                width: parent.width
                height: 32
                Button {
                    x: 14
                    text: "Try again"
                    onClicked: win.activate(win.apps.length)
                }
            }
            Item {
                visible: win.canPull
                width: parent.width
                height: 32
                Button {
                    x: 14
                    primary: true
                    text: "Download the model"
                    onClicked: {
                        Quickshell.execDetached(["grace-launch", "run", "cherrycola", "pull"]);
                        Ui.launcherOpen = false;
                    }
                }
            }
        }
    }
}
