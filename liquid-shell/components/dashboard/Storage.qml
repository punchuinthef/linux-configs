import QtQuick
import QtQuick.Layouts
import "../../theme" as Styling

Item {
    id: root
    property bool active: false
    onActiveChanged: if (active) storageService.refresh()

    StorageService { id: storageService }

    function prettyBytes(value) {
        if (!Number.isFinite(value) || value < 0) return "—"
        const units = ["B", "KiB", "MiB", "GiB", "TiB"]
        // Use binary units to agree with df -B1.
        let size = value
        let i = 0
        while (size >= 1024 && i < units.length - 1) {
            size /= 1024
            i++
        }
        return size.toFixed(i === 0 ? 0 : 1) + " " + units[i]
    }

    readonly property var sections: [
        { key: "home", name: "Home", path: "/home" },
        { key: "games", name: "Games", path: "/games" },
        { key: "music", name: "Music", path: "/music" },
        { key: "backup", name: "SudoSaveMe", path: "/run/media/radio/SudoSaveMe" }
    ]

    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "STORAGE"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 15
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: storageService.busy ? "Checking…" : "↻"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: storageService.busy ? 12 : 23
                    MouseArea {
                        anchors.fill: parent
                        enabled: !storageService.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: storageService.refresh()
                    }
                }
            }

            Repeater {
                model: root.sections
                delegate: ColumnLayout {
                    id: section
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 9
                    readonly property var info: storageService.drives[modelData.key]
                    readonly property bool mounted: info && info.mounted

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: section.modelData.name
                            color: Styling.Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Text {
                            text: !section.info ? "—" : section.mounted ? section.info.percent + "%" : "Not mounted"
                            color: Styling.Theme.textPrimary
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 20
                        Layout.preferredHeight: 20
                        radius: height / 2
                        color: "#44AAAAAA"
                        clip: true
                        Rectangle {
                            width: section.mounted ? parent.width * section.info.percent / 100 : 0
                            height: parent.height
                            radius: parent.radius
                            color: Styling.Theme.textPrimary
                            opacity: 0.8
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: section.mounted
                                ? root.prettyBytes(section.info.used) + " used of " + root.prettyBytes(section.info.total)
                                : section.info && section.info.status === "error" ? "Unable to read filesystem" : "Drive not mounted"
                            color: Styling.Theme.textPrimary
                            opacity: 0.75
                            font.pixelSize: 11
                            Layout.fillWidth: true
                        }
                        Text {
                            text: section.modelData.path
                            color: Styling.Theme.textPrimary
                            opacity: 0.5
                            font.pixelSize: 10
                            elide: Text.ElideLeft
                            Layout.maximumWidth: 230
                        }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 7
                        Layout.preferredHeight: 1
                        color: Styling.Theme.textPrimary
                        opacity: 0.12
                    }
                }
            }
            Item { Layout.fillHeight: true }
            Text {
                text: storageService.lastUpdated ? "Last checked: " + storageService.lastUpdated + " · Refresh on open" : "Refreshes when opened"
                color: Styling.Theme.textPrimary
                opacity: 0.55
                font.pixelSize: 10
            }
        }
    }
}
