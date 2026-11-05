import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../theme" as Styling

Item {
    id: gallery

    // Gallery state
    property bool active: false
    // Layout dimensions
    readonly property int columns: 3
    readonly property int rowHeight: 175
    readonly property int headerHeight: 120

    // Height required to display all wallpaper rows
    readonly property int contentHeight:
    Math.ceil(wallpapers.length / columns) * rowHeight
    + headerHeight
    property var wallpapers: []

    // Wallpaper selection state
    property string selectedWallpaper: ""
    property bool applyingWallpaper: false

    // Emitted after hyprpaper successfully applies a wallpaper
    signal wallpaperApplied()

    // Refresh whenever the wallpaper picker opens
    onActiveChanged: {
        if (active)
            refresh()
    }

    function refresh() {
        if (wallpaperScanner.running)
            return

        wallpaperScanner.running = true
    }

    // Discover wallpapers recursively
    Process {
        id: wallpaperScanner

        command: [
            "bash",
            Qt.resolvedUrl("../scripts/list-wallpapers.sh")
                .toString()
                .replace(/^file:\/\//, "")
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                gallery.wallpapers = this.text
                    .split("\n")
                    .filter(path => path.length > 0)
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Wallpaper scan failed:", exitCode)
        }
    }

    // Apply the selected wallpaper using hyprpaper
    Process {
        id: wallpaperSetter

        command: [
            "bash",
            Qt.resolvedUrl("../scripts/set-wallpaper.sh")
                .toString()
                .replace(/^file:\/\//, ""),
            gallery.selectedWallpaper
        ]

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("hyprpaper:", this.text)
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.warn("hyprpaper:", this.text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            gallery.applyingWallpaper = false

            if (exitCode === 0) {
                console.log("Wallpaper applied successfully")
                gallery.wallpaperApplied()
            } else {
                console.warn(
                    "Wallpaper change failed with exit code:",
                    exitCode
                )
            }
        }
    }

    // Gallery interface
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Wallpaper Gallery"
                color: Styling.Theme.textPrimary
                font.pixelSize: 24
                font.bold: true

                Layout.fillWidth: true
            }

            // Manual refresh button
            Rectangle {
                implicitWidth: 100
                implicitHeight: 34
                radius: 10
                color: "#33FFFFFF"

                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    color: Styling.Theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: gallery.refresh()
                }
            }
        }

        // Wallpaper counter
        Text {
            text: gallery.wallpapers.length + " wallpapers found"
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
        }

        // Scrollable thumbnail gallery
        GridView {
            id: wallpaperGrid

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true

            // Three thumbnails per row
            cellWidth: width / gallery.columns
            cellHeight: gallery.rowHeight

            model: gallery.wallpapers

            delegate: Item {
                id: wallpaperItem

                required property string modelData

                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 6

                    radius: 12
                    color: "#33000000"
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Image {
                            width: parent.width
                            height: 125

                            source: "file://" + wallpaperItem.modelData

                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true

                            sourceSize.width: 320
                            sourceSize.height: 180
                        }

                        Text {
                            width: parent.width

                            text: wallpaperItem.modelData
                                .split("/")
                                .pop()

                            color: Styling.Theme.textPrimary
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Click to apply wallpaper
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        enabled: !gallery.applyingWallpaper

                        onClicked: {
                            gallery.selectedWallpaper = wallpaperItem.modelData
                            gallery.applyingWallpaper = true
                            wallpaperSetter.running = true
                        }
                    }
                }
            }

            ScrollBar.vertical: ScrollBar {}
        }
    }
}

