import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    property string pendingAction: ""
    property string selectedMode: ""

    function refreshAppearance() {
        if (appearanceReadProcess.running || appearanceProcess.running)
            return
        appearanceReadProcess.command = [
            "python3",
            Quickshell.env("HOME") + "/.config/quickshell/liquid-shell/scripts/appearance-manager.py"
        ]
        appearanceReadProcess.running = true
    }

    Process {
        id: appearanceReadProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const match = this.text.match(/(?:^|\n)Preference:\s*(light|dark|auto)/)
                if (match)
                    root.selectedMode = match[1]
            }
        }
    }

    Timer {
        interval: 10000
        running: root.visible
        repeat: true
        onTriggered: root.refreshAppearance()
    }

    Component.onCompleted: refreshAppearance()
    readonly property string iconRoot: Qt.resolvedUrl("../../assets/icons/")

    Process {
        id: appearanceProcess
        running: false
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("Appearance manager failed:", exitCode)
            else
                root.refreshAppearance()
        }
    }

    Process {
        id: actionProcess
        running: false
    }

    Timer {
        id: confirmationTimer
        interval: 5000
        repeat: false
        onTriggered: root.pendingAction = ""
    }

    function changeAppearance(mode) {
        if (appearanceProcess.running)
            return

        appearanceProcess.command = [
            "python3",
	   Quickshell.env("HOME") + "/.config/quickshell/liquid-shell/scripts/appearance-manager.py",            
	    "--mode", mode
        ]
        appearanceProcess.running = true
    }

    function activate(action) {
        if (action === "lock") {
            pendingAction = ""
            confirmationTimer.stop()
            if (!actionProcess.running) {
                actionProcess.command = ["loginctl", "lock-session"]
                actionProcess.running = true
            }
            return
        }

        if (pendingAction !== action) {
            pendingAction = action
            confirmationTimer.restart()
            return
        }

        if (actionProcess.running)
            return

        pendingAction = ""
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
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 18
        spacing: 15

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Appearance"
            color: Styling.Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.Medium
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
                model: [
                    { mode: "light", label: "Light", file: "sun.svg" },
                    { mode: "dark", label: "Dark", file: "moon.svg" },
                    { mode: "auto", label: "Auto", file: "refresh-ccw.svg" }
                ]

                delegate: Button {
                    required property var modelData
                    readonly property bool selected: root.selectedMode === modelData.mode

                    width: 42
                    height: 42
                    hoverEnabled: true
                    display: AbstractButton.IconOnly

                    icon.source: root.iconRoot + "Appearance/" + modelData.file
                    icon.width: 22
                    icon.height: 22
                    icon.color: Styling.Theme.textPrimary

                    background: Rectangle {
                        radius: width / 2
                        color: parent.selected ? Styling.Theme.glassBorder
                            : parent.hovered ? Styling.Theme.glassBorder : "transparent"
                        border.width: parent.selected ? 2 : 1
                        border.color: parent.selected ? Styling.Theme.primary : Styling.Theme.textSecondary
                    }

                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: modelData.label

                    onClicked: root.changeAppearance(modelData.mode)
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Styling.Theme.glassBorder
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.pendingAction === ""
                ? "Actions"
                : "Confirm " + root.pendingAction + "?"
            color: Styling.Theme.textPrimary
            font.pixelSize: 14
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 7

            Repeater {
                model: [
                    { action: "lock", label: "Lock", file: "lock.svg" },
                    { action: "logout", label: "Logout", file: "log-out.svg" },
                    { action: "reboot", label: "Reboot", file: "refresh-ccw.svg" },
                    { action: "shutdown", label: "Shut down", file: "power.svg" }
                ]

                delegate: Button {
                    required property var modelData
                    readonly property bool confirming: root.pendingAction === modelData.action

                    width: 36
                    height: 36
                    hoverEnabled: true
                    display: AbstractButton.IconOnly

                    icon.source: root.iconRoot + "Actions/" + modelData.file
                    icon.width: 19
                    icon.height: 19
                    icon.color: confirming ? Styling.Theme.textPrimary : Styling.Theme.textSecondary

                    background: Rectangle {
                        radius: width / 2
                        color: parent.confirming
                            ? Styling.Theme.primary
                            : parent.hovered ? Styling.Theme.glassBorder : "transparent"
                        border.width: 1
                        border.color: parent.confirming
                            ? Styling.Theme.primary
                            : Styling.Theme.textSecondary
                    }

                    ToolTip.visible: hovered
                    ToolTip.delay: 400
                    ToolTip.text: confirming
                        ? "Click again to confirm " + modelData.label
                        : modelData.label

                    onClicked: root.activate(modelData.action)
                }
            }
        }

        // Divider below Actions; the Storage group remains bottom-anchored.
        Rectangle {
            width: parent.width
            height: 1
            color: Styling.Theme.glassBorder
        }
    }

    StorageGauges {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottomMargin: 12
        height: 130
    }

}
