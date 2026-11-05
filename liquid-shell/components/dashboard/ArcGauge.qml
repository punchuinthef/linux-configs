import QtQuick
import "../../theme" as Styling

Item {
    id: root

    // Usage is normalized: 0.0 (empty) to 1.0 (full).
    property real value: 0
    property bool ready: true
    property bool animated: true
    // Opt in for performance gauges; storage gauges keep the Matugen accent.
    property bool utilizationColors: false
    property real minimumVisibleFraction: 0.0
    readonly property color targetArcColor: utilizationColors
        ? (value <= 0.25 ? "#4CAF50" : value <= 0.75 ? "#FFC107" : "#F44336")
        : Styling.Theme.primary
    property color displayedArcColor: targetArcColor
    Behavior on displayedArcColor {
        enabled: root.animated
        ColorAnimation { duration: 300 }
    }
    onTargetArcColorChanged: displayedArcColor = targetArcColor
    onDisplayedArcColorChanged: arc.requestPaint()
    property string label: ""
    property url iconSource: "" // Optional SVG path; blank uses the text label.
    property bool showPercentage: true // Storage can position its own percentage label.

    implicitWidth: 96
    implicitHeight: 110

    property real displayedValue: 0
    Behavior on displayedValue {
        enabled: root.animated
        NumberAnimation { duration: 450; easing.type: Easing.InOutCubic }
    }

    onValueChanged: displayedValue = Math.max(0, Math.min(1, value))
    onDisplayedValueChanged: arc.requestPaint()
    Component.onCompleted: displayedValue = Math.max(0, Math.min(1, value))

    Canvas {
        id: arc
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 96
        height: 79

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            const centerX = width / 2
            const centerY = 43
            const radius = 33
            const start = Math.PI * 0.75
            const sweep = Math.PI * 1.5

            ctx.lineWidth = 9
            ctx.lineCap = "round"

            ctx.beginPath()
            ctx.strokeStyle = Styling.Theme.glassBorder
            ctx.arc(centerX, centerY, radius, start, start + sweep, false)
            ctx.stroke()

            if (root.ready && root.displayedValue > 0) {
                ctx.beginPath()
                ctx.strokeStyle = root.displayedArcColor
                ctx.arc(centerX, centerY, radius, start,
                        start + sweep * Math.min(1, Math.max(0, root.minimumVisibleFraction, root.displayedValue)), false)
                ctx.stroke()
            }
        }

        Image {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 3
            width: 23
            height: 23
            source: root.iconSource
            visible: root.iconSource.toString().length > 0
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 23
            sourceSize.height: 23
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 3
            visible: root.iconSource.toString().length === 0
            text: root.label
            color: Styling.Theme.textPrimary
            font.pixelSize: 13
            font.bold: true
        }
    }

    Text {
        anchors.top: arc.bottom
        anchors.topMargin: 0
        visible: root.showPercentage
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.ready ? Math.round(root.value * 100) + "%" : "—"
        color: Styling.Theme.textPrimary
        font.pixelSize: 16
        font.bold: true
    }

    Connections {
        target: Styling.Theme
        function onPrimaryChanged() { arc.requestPaint() }
        function onGlassBorderChanged() { arc.requestPaint() }
    }
}
