pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Agent approval requests from `grace-approve`. A request waits until the user answers;
// nothing here answers on its own, and when the shell isn't running grace-approve denies.
Singleton {
    id: root

    property var pending: [] // [{ id, agent, command, cwd, reply }]
    readonly property var current: pending.length ? pending[0] : null
    readonly property string replyDir: Quickshell.env("XDG_RUNTIME_DIR") + "/grace/approvals/"

    function esc(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Show control, bidi and zero-width characters as visible escapes so a request can't disguise its command.
    function visible(s) {
        return String(s).replace(/[\u0000-\u001f\u007f-\u009f\u200b-\u200f\u202a-\u202e\u2060-\u2069\ufeff]/g, c => "\\u" + c.charCodeAt(0).toString(16).padStart(4, "0"));
    }

    function answer(req, allow) {
        // reply is always replyDir + a validated id (see request), never a path a caller picks.
        Quickshell.execDetached(["sh", "-c", "[ -p \"$2\" ] && timeout 5 sh -c 'printf %s \"$1\" > \"$2\"' sh \"$1\" \"$2\"", "sh", allow ? "allow" : "deny", req.reply]);
        pending = pending.filter(p => p.id !== req.id);
    }

    IpcHandler {
        target: "approvals"

        function request(id: string, agent: string, command: string, cwd: string): void {
            if (!/^[0-9]+-[0-9]+$/.test(id) || root.pending.some(p => p.id === id))
                return;
            root.pending = root.pending.concat([{ id, agent: root.visible(agent), command: root.visible(command), cwd: root.visible(cwd), reply: root.replyDir + id }]);
        }
        function cancel(id: string): void {
            root.pending = root.pending.filter(p => p.id !== id);
        }
        function count(): int {
            return root.pending.length;
        }
    }
}
