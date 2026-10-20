import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.widgets

// Updates through pacman (checkupdates from pacman-contrib, no root) and the AUR (yay). Installing
// and updating need administrator rights, so they run in a terminal where you type your password.
ColumnLayout {
    id: page
    readonly property string description: "Keep GraceOS up to date and install software from Arch's repos and the AUR."
    spacing: 14

    property var info: ({})       // packages, explicit, last update, graceos repo
    property var updates: null    // null: not checked; [] none; ["name old -> new", ...]
    property bool checking: false
    readonly property string updater: info.yay === "1" ? "yay" : "sudo pacman"

    Process {
        command: ["sh", "-c", "echo packages=$(pacman -Q | wc -l); echo explicit=$(pacman -Qe | wc -l); echo last=$(grep -h 'starting full system upgrade' /var/log/pacman.log 2>/dev/null | tail -1 | cut -c2-17); grep -q '^\\[graceos\\]' /etc/pacman.conf && echo graceos=1; command -v yay >/dev/null && echo yay=1; command -v checkupdates >/dev/null && echo checkupdates=1; true"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {};
                for (const l of text.split("\n")) {
                    const i = l.indexOf("=");
                    if (i > 0)
                        o[l.slice(0, i)] = l.slice(i + 1);
                }
                page.info = o;
            }
        }
    }
    Process {
        id: check
        // checkupdates syncs a private copy of the databases, so it needs no root; yay -Qua checks the AUR.
        command: ["sh", "-c", "checkupdates 2>/dev/null; command -v yay >/dev/null && yay -Qua 2>/dev/null; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                page.updates = text.split("\n").filter(l => l.trim());
                page.checking = false;
            }
        }
    }

    SettingsBox {
        SettingsRow {
            title: page.checking ? "Checking for updates…" : page.updates === null ? "Updates" : page.updates.length ? `${page.updates.length} update${page.updates.length > 1 ? "s" : ""} available` : "Everything is up to date"
            description: page.info.last ? "Last full update: " + page.info.last.replace("T", " at ") : "Not updated since it was installed"
            Row {
                spacing: 6
                Button {
                    visible: page.info.checkupdates === "1"
                    text: "Check"
                    onClicked: {
                        page.checking = true;
                        check.running = true;
                    }
                }
                Button {
                    text: "Update now"
                    primary: true
                    onClicked: Quickshell.execDetached(["grace-launch", "run", ...page.updater.split(" "), "-Syu"])
                }
            }
        }
        Repeater {
            model: (page.updates ?? []).slice(0, 12)
            SettingsRow {
                required property string modelData
                title: modelData.split(" ")[0]
                T {
                    text: modelData.split(" ").slice(1).join(" ")
                    color: Theme.textSecondary
                    font.family: "Fira Code"
                    font.pixelSize: 11
                }
            }
        }
        SettingsRow {
            visible: (page.updates ?? []).length > 12
            title: `and ${(page.updates ?? []).length - 12} more`
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Install software"
            description: page.info.yay === "1" ? "A package name from Arch's repos or the AUR" : "A package name from Arch's repos"
            Row {
                spacing: 6
                TextField {
                    id: pkg
                    width: 180
                    placeholder: "firefox"
                    onAccepted: install.clicked()
                }
                Button {
                    id: install
                    text: "Install"
                    onClicked: {
                        const name = pkg.text.trim();
                        if (/^[a-z0-9@._+-]+$/.test(name))
                            Quickshell.execDetached(["grace-launch", "run", ...page.updater.split(" "), "-S", name]);
                        pkg.text = "";
                    }
                }
            }
        }
        SettingsRow {
            title: "Find software"
            description: "Search Arch's packages and the AUR in your browser"
            link: true
            onActivated: Quickshell.execDetached(["xdg-open", "https://archlinux.org/packages/"])
        }
    }

    SettingsBox {
        SettingsRow {
            title: "Installed packages"
            description: page.info.packages ? `${page.info.packages} in total, ${page.info.explicit} installed on purpose` : ""
        }
        SettingsRow {
            title: "GraceOS package repo"
            description: page.info.graceos === "1" ? "Connected: GraceOS's own packages update with everything else" : "Not set up on this system (the live ISO uses a copy)"
        }
    }
}
