import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.widgets

// What this PC is and runs, read once when the page opens.
ColumnLayout {
    id: page
    readonly property string description: ""
    spacing: 14

    property var i: ({})
    readonly property var rows: [["Device name", i.host], ["Operating system", i.os], ["Kernel", i.kernel], ["Desktop", "Grace Candyland on Hyprland " + (i.hypr ?? "")], ["Processor", i.cpu], ["Memory", i.mem], ["Graphics", i.gpu], ["Disk", i.disk], ["Uptime", i.up]]

    Process {
        running: true
        command: ["sh", "-c", `
            . /etc/os-release 2>/dev/null
            echo "os=$PRETTY_NAME \${BUILD_ID:+($BUILD_ID)}"
            echo "host=$(cat /etc/hostname 2>/dev/null || uname -n)"
            echo "kernel=$(uname -r)"
            echo "hypr=$(hyprctl version -j 2>/dev/null | sed -n 's/.*"tag": *"\\([^"]*\\)".*/\\1/p' | head -1)"
            echo "cpu=$(sed -n 's/^model name[[:space:]]*: //p' /proc/cpuinfo | head -1) ($(nproc) threads)"
            echo "mem=$(awk '/MemTotal/ {printf "%.1f GB", $2/1048576}' /proc/meminfo)"
            echo "gpu=$(lspci 2>/dev/null | sed -n 's/.*\\(VGA\\|3D\\|Display\\)[^:]*: //p' | head -2 | paste -sd ',')"
            if [ "$(findmnt -no FSTYPE /)" = overlay ]; then echo "disk=Live session: nothing is saved to disk"
            else echo "disk=$(df -h / | awk 'NR==2 {print $3 " used of " $2}')"; fi
            echo "up=$(uptime -p | sed 's/^up //')"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const l of text.split("\n")) {
                    const k = l.indexOf("=");
                    if (k > 0)
                        o[l.slice(0, k)] = l.slice(k + 1).trim();
                }
                page.i = o;
            }
        }
    }

    Column {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 6
        Layout.bottomMargin: 6
        spacing: 4
        T {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "GraceOS"
            color: Theme.textStrong
            font.pixelSize: 34
            font.weight: Font.DemiBold
        }
        T {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Arch-based, AI-native, built for developers"
            color: Theme.textSecondary
        }
    }

    SettingsBox {
        Repeater {
            model: page.rows
            SettingsRow {
                required property var modelData
                title: modelData[0]
                T {
                    text: modelData[1] || "…"
                    color: Theme.textSecondary
                    width: Math.min(implicitWidth, 420)
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Copy system details"
            description: "Handy when reporting a problem"
            Button {
                text: "Copy"
                onClicked: {
                    Quickshell.clipboardText = page.rows.map(r => `${r[0]}: ${r[1] ?? ""}`).join("\n");
                    text = "Copied";
                }
            }
        }
        SettingsRow {
            title: "Report a problem"
            link: true
            onActivated: Quickshell.execDetached(["xdg-open", "https://github.com/itsHarshDabas/GraceOS/issues"])
        }
        SettingsRow {
            title: "GraceOS on GitHub"
            link: true
            onActivated: Quickshell.execDetached(["xdg-open", "https://github.com/itsHarshDabas/GraceOS"])
        }
    }
}
