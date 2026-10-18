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

    function answer(req, allow) {
        // Only ever write into a FIFO under grace-approve's own directory, never to a path a caller picks.
        if (req.reply.startsWith(replyDir) && !req.reply.includes("/.."))
            Quickshell.execDetached(["sh", "-c", "[ -p \"$2\" ] && timeout 5 sh -c 'printf %s \"$1\" > \"$2\"' sh \"$1\" \"$2\"", "sh", allow ? "allow" : "deny", req.reply]);
        pending = pending.filter(p => p.id !== req.id);
    }

    IpcHandler {
        target: "approvals"

        function request(id: string, agent: string, command: string, cwd: string, reply: string): void {
            root.pending = root.pending.concat([{ id, agent, command, cwd, reply }]);
        }
        function cancel(id: string): void {
            root.pending = root.pending.filter(p => p.id !== id);
        }
        function count(): int {
            return root.pending.length;
        }
    }
}
