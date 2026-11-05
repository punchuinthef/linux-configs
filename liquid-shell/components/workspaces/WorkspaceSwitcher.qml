
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../../theme" as Styling

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        Text {
            text: "Workspaces"
            color: Styling.Theme.textPrimary
            font.pixelSize: 20
            font.bold: true
        }

        Text {
            text: "Active Hyprland workspaces"
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
        }

        Flow {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: Hyprland.workspaces

                delegate: Rectangle {
                    required property var modelData

                    width: 64
                    height: 64
                    radius: 12

                    property bool isActive:
                        Hyprland.focusedWorkspace === modelData

                    color: isActive
                        ? "#44FFFFFF"
                        : "#16FFFFFF"

                    border.width: isActive ? 2 : 1
                    border.color: Styling.Theme.glassBorder

                    Text {
                        anchors.centerIn: parent
                        text: modelData.name
                        color: Styling.Theme.textPrimary
                        font.pixelSize: 20
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

        Item {
            Layout.fillHeight: true
        }
    }
}

