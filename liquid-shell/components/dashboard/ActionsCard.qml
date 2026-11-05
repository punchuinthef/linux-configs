import QtQuick
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    // Destructive actions require a second click within five seconds.
    property string pendingAction: ""

    Timer {
        id: confirmationTimer
        interval: 5000
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    Process {
        id: actionProcess
        running: false
    }

    function activate(action) {
        if (action === "lock") {
            root.pendingAction = ""
            confirmationTimer.stop()
            actionProcess.command = ["loginctl", "lock-session"]
            actionProcess.running = true
            return
        }

        if (root.pendingAction !== action) {
            root.pendingAction = action
            confirmationTimer.restart()
            return
        }

        root.pendingAction = ""
        confirmationTimer.stop()

        if (action === "logout")
            actionProcess.command = ["hyprctl", "dispatch", "exit"]
        else if (action === "reboot")
            actionProcess.command = ["systemctl", "reboot"]
        else if (action === "shutdown")
            actionProcess.command = ["systemctl", "poweroff"]
        else
            return

        actionProcess.running = true
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.pendingAction === "" ? "ACTIONS" : "CONFIRM " + root.pendingAction.toUpperCase() + "?"
            color: Styling.Theme.textSecondary
            font.pixelSize: 11
            font.bold: true
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6

            Repeater {
                model: [
                    { action: "lock", label: "Lock" },
                    { action: "logout", label: "Logout" },
                    { action: "reboot", label: "Reboot" },
                    { action: "shutdown", label: "Power" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    readonly property bool confirming: root.pendingAction === modelData.action

                    width: 58
                    height: 29
                    radius: 8
                    color: confirming ? Styling.Theme.primary : Styling.Theme.glassBorder

                    Text {
                        anchors.centerIn: parent
                        text: parent.confirming ? "Confirm" : parent.modelData.label
                        color: Styling.Theme.textPrimary
                        font.pixelSize: 11
                        font.bold: parent.confirming
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(parent.modelData.action)
                    }
                }
            }
        }
    }
}
