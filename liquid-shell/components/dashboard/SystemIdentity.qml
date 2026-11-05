import QtQuick
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    implicitWidth: details.implicitWidth
    implicitHeight: details.implicitHeight

    property string osName: "Loading..."

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const match = text().match(/^PRETTY_NAME=(.*)$/m)
            root.osName = match
                ? match[1].trim().replace(/^\"|\"$/g, "")
                : "Unavailable"
        }
    }

    Column {
        id: details
        anchors.centerIn: parent
        spacing: 7

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "SYSTEM ID"
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "OS: " + root.osName
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "WM: Hyprland"
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
        }

        Uptime {
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
