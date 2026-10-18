pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    readonly property var list: [...server.trackedNotifications.values].reverse() // newest first
    property var banners: []

    function clearAll() {
        for (const n of [...server.trackedNotifications.values])
            n.dismiss();
    }
    function hideBanner(n) {
        banners = banners.filter(b => b !== n);
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: n => {
            n.tracked = true;
            // Do Not Disturb keeps notifications in the list but skips the banner, except critical ones.
            if (!Config.dnd || n.urgency === NotificationUrgency.Critical)
                root.banners = [n].concat(root.banners).slice(0, 4);
        }
    }
}
