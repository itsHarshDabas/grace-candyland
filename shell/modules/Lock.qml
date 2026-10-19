import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.widgets

// The lock screen: "Goodness GraceOS". Uses the compositor's session lock, so if the shell
// dies while locked the screen stays locked. The password is checked by PAM's login stack.
Scope {
    id: root

    property bool locked: false
    property bool busy: false
    property string status: "" // PAM's own message, or why the last try failed
    property string attempt: ""
    readonly property string user: Quickshell.env("USER") || ""
    signal finished // clears every screen's password field

    function lock() {
        status = "";
        locked = true;
    }
    function submit(password) {
        if (busy)
            return;
        attempt = password;
        busy = true;
        status = "";
        if (!pam.start()) {
            busy = false;
            status = "Couldn't start the password check.";
        }
    }

    PamContext {
        id: pam
        onPamMessage: {
            if (responseRequired)
                respond(root.attempt);
            else if (message)
                root.status = message;
        }
        onCompleted: result => {
            root.busy = false;
            root.attempt = "";
            root.finished();
            if (result === PamResult.Success)
                root.locked = false;
            else
                root.status = result === PamResult.MaxTries ? "Too many tries. Wait a few minutes." : "Wrong password. Try again.";
        }
        onError: error => {
            root.busy = false;
            root.attempt = "";
            root.finished();
            root.status = "Couldn't check the password (" + PamError.toString(error) + ").";
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Theme.desktop

            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeWidth: -1
                    fillGradient: RadialGradient {
                        centerX: surface.width * 0.5
                        centerY: surface.height * 0.42
                        centerRadius: surface.width * 0.6
                        focalX: centerX
                        focalY: centerY
                        GradientStop { position: 0; color: Theme.accent.tint }
                        GradientStop { position: 1; color: "transparent" }
                    }
                    PathRectangle { width: surface.width; height: surface.height }
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            // One centered stack; the clock shrinks on short screens so nothing overlaps.
            Column {
                anchors.centerIn: parent
                spacing: 12
                width: 300

                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Theme.textStrong
                    font.pixelSize: Math.round(Math.min(84, surface.height * 0.11))
                    font.weight: Font.Light
                }
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Theme.textSecondary
                    font.pixelSize: 15
                }
                Item {
                    width: 1
                    height: Math.min(40, surface.height * 0.04)
                }
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 64
                    height: 64
                    radius: 32
                    color: Theme.accent.fill
                    T {
                        anchors.centerIn: parent
                        text: root.user.slice(0, 1).toUpperCase()
                        color: "white"
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                    }
                }
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Goodness GraceOS"
                    color: Theme.textStrong
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }
                T {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.user
                    color: Theme.textSecondary
                    font.pixelSize: 14
                }

                Rectangle {
                    width: parent.width
                    height: 42
                    radius: 21
                    color: Theme.controlStrong
                    border.width: 1
                    border.color: field.activeFocus ? Theme.accent.base : Theme.hair

                    TextInput {
                        id: field
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 46
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: Theme.text
                        font.family: Theme.font
                        font.pixelSize: 16
                        enabled: !root.busy
                        focus: true
                        onAccepted: root.submit(text)
                        Component.onCompleted: forceActiveFocus()

                        Connections {
                            target: root
                            function onFinished() {
                                field.text = "";
                                field.forceActiveFocus();
                            }
                        }
                    }
                    T {
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text === ""
                        text: root.busy ? "Checking…" : "Password"
                        color: Theme.textTertiary
                        font.pixelSize: 15
                    }
                    RoundButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "chevronright"
                        onClicked: root.submit(field.text)
                    }
                }

                T {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: root.status
                    color: Theme.error
                    font.pixelSize: 13
                }
            }
        }
    }
}
