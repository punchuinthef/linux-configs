
import QtQuick
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    implicitWidth: uptimeText.implicitWidth
    implicitHeight: uptimeText.implicitHeight

    property string uptime: "Loading..."

    function updateUptime() {
        uptimeFile.reload()
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"

        onLoaded: {
            const seconds = Math.floor(
                Number(text().trim().split(/\s+/)[0])
            )

            if (!Number.isFinite(seconds)) {
                root.uptime = "Unavailable"
                return
            }

            const days = Math.floor(seconds / 86400)
            const hours = Math.floor((seconds % 86400) / 3600)
            const minutes = Math.floor((seconds % 3600) / 60)

            if (days > 0) {
                root.uptime = days + "d " + hours + "h " + minutes + "m"
            } else if (hours > 0) {
                root.uptime = hours + "h " + minutes + "m"
            } else {
                root.uptime = minutes + "m"
            }
        }
    }

    Timer {
        interval: 60000
        running: root.visible
        repeat: true
        triggeredOnStart: true

        onTriggered: root.updateUptime()
    }

    Text {
        id: uptimeText
        text: "Uptime: " + root.uptime

        color: Styling.Theme.textSecondary
        font.pixelSize: 13
    }
}

