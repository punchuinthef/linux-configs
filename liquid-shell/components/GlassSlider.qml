import QtQuick
import "../theme" as Styling

// Simple themed slider; filename, signals and public properties are unchanged.
Item {
    id: root
    property real value: 0
    property bool interactive: true
    property bool subdued: false
    property color accent: Styling.Theme.primary
    property color trackColor: Styling.Theme.panelBorder

    signal moved(real value)
    signal committed(real value)
    readonly property bool dragging: dragArea.pressed

    implicitHeight: 34
    implicitWidth: 180
    readonly property real fraction: Math.max(0, Math.min(1, value))

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        width: track.width * root.fraction
        height: track.height
        radius: track.radius
        color: root.subdued ? Styling.Theme.textSecondary : root.accent
        opacity: root.subdued ? 0.45 : 1
        Behavior on width {
            enabled: !dragArea.pressed
            NumberAnimation { duration: 110 }
        }
    }

    Rectangle {
        id: thumb
        width: 16
        height: 16
        radius: width / 2
        x: (root.width - width) * root.fraction
        anchors.verticalCenter: parent.verticalCenter
        color: root.accent
        border.width: 1
        border.color: Styling.Theme.surface
        opacity: root.interactive ? 1 : 0.5
        Behavior on x {
            enabled: !dragArea.pressed
            NumberAnimation { duration: 110; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        function updateFromMouse(mouseX) {
            root.moved(Math.max(0, Math.min(1, mouseX / Math.max(1, width))))
        }
        onPressed: mouse => updateFromMouse(mouse.x)
        onReleased: mouse => root.committed(Math.max(0, Math.min(1, mouse.x / Math.max(1, width))))
        onPositionChanged: mouse => { if (pressed) updateFromMouse(mouse.x) }
    }
}
