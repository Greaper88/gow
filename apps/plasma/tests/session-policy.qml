import QtQuick
import org.kde.config as KConfig
import org.kde.plasma.private.sessions as Sessions

Item {
    Sessions.SessionManagement { id: session }
    Timer {
        interval: 2000
        running: true
        onTriggered: {
            let failures = [];
            if (!session.canLogout) failures.push("Log Out is unavailable");
            for (const capability of ["canLock", "canSwitchUser", "canSuspend", "canHibernate", "canReboot", "canShutdown"]) {
                if (session[capability]) failures.push("Unsupported action is exposed: " + capability);
            }
            for (const module of ["kcm_clock", "kcm_sddm", "kcm_users", "kcm_screenlocker", "kcm_networkmanagement"]) {
                if (KConfig.KAuthorized.authorizeControlModule(module)) failures.push("Machine setting is exposed: " + module);
            }
            if (!KConfig.KAuthorized.authorizeControlModule("kcm_colors")) failures.push("Appearance settings were disabled");
            console.warn(failures.length ? failures.join("\n") : "PASS: container session capabilities and settings policy");
            Qt.exit(failures.length ? 1 : 0);
        }
    }
}
