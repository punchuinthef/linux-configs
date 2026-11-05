import QtQuick
import Quickshell.Hyprland
import "../../theme" as Styling

Item {
    id: root

    Column {
        anchors.top: parent.top
        anchors.topMargin: 16
        width: parent.width
        spacing: 12

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "WORKSPACES"
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
            font.bold: true
        }

        Flow {
            id: workspaceFlow
            width: parent.width
            spacing: 6

            Repeater {
                model: Hyprland.workspaces

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool isActive: Hyprland.focusedWorkspace === modelData

                    width: 36
                    height: 36
                    radius: 11
                    color: isActive ? Styling.Theme.glassBorder : Styling.Theme.glassBackground
                    border.width: isActive ? 2 : 1
                    border.color: Styling.Theme.glassBorder

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: Styling.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: parent.isActive
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch(
                                'hl.dsp.focus({ workspace = "' + modelData.id + '" })'
                            )
                        }
                    }
                }
            }
        }
    }
}
