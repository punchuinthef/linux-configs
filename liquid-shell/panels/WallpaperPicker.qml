

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "../components"
import "../theme" as Styling

Scope {
    id: root

    property bool pickerOpen: false

    // Panel dimensions
    readonly property int panelWidth: 900
    readonly property int maxPanelHeight: 1050
    readonly property int minPanelHeight: 300

    // Gallery determines how tall the panel needs to be
    property int galleryContentHeight: 300

    readonly property int calculatedHeight: Math.max(
        minPanelHeight,
        Math.min(galleryContentHeight, maxPanelHeight)
    )

    IpcHandler {
        target: "wallpaper"

        function toggle(): void {
            root.pickerOpen = !root.pickerOpen
        }

        function close(): void {
            root.pickerOpen = false
        }
    }

    PanelWindow {
        id: pickerWindow

        visible: root.pickerOpen

        anchors {
            top: true
        }

        implicitWidth: root.panelWidth
        implicitHeight: root.calculatedHeight

        margins.top: 100

        color: "transparent"
        exclusiveZone: 0
        aboveWindows: true

        WlrLayershell.keyboardFocus: root.pickerOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        GlassPanel {
            anchors.fill: parent

            WallpaperGallery {
                id: gallery

                anchors.fill: parent
                active: root.pickerOpen

                onContentHeightChanged: {
                    root.galleryContentHeight = contentHeight
                }

                Component.onCompleted: {
                    root.galleryContentHeight = contentHeight
                }

                onWallpaperApplied: {
                    root.pickerOpen = false
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: root.pickerOpen

            onActivated: root.pickerOpen = false
        }
    }
}

