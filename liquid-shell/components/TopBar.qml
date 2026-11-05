import Quickshell
import QtQuick
import Quickshell.Wayland
import "../theme" as Styling

Scope {
    id: root

    property bool dropdownOpen: false
    property bool dropdownHovered: false
    property bool suppressHoverOpen: false
    // Keep the panel rendered until its closing animation has finished.
    property bool dropdownRendered: false
    // Visual height changes by tab; the interactive viewport stays fixed.
    readonly property real visualDropdownHeight: dropdownContent.currentTab === 0 ? 690 : 850

    onDropdownOpenChanged: {
        if (dropdownOpen) {
            retractAnimation.stop()
            dropdownRendered = true
            revealAnimation.restart()
        } else {
            revealAnimation.stop()
            retractAnimation.restart()
        }
    }

    Timer {
        id: closeTimer
        interval: 1500
        repeat: false

        onTriggered: {
            if (!buttonArea.containsMouse && !root.dropdownHovered)
                root.dropdownOpen = false
        }
    }

    PanelWindow {
        id: bar

        anchors {
            top: true
            left: true
            right: true
        }

        // Keep the backing window large enough for the tallest tab.
        implicitHeight: Styling.Theme.barHeight + 860
        color: "transparent"

        exclusiveZone: Styling.Theme.barHeight
        aboveWindows: true

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        focusable: true

        // The bar and only the currently revealed dropdown are interactive.
        // The rest of the large transparent window remains click-through.
        mask: Region {
            width: bar.width
            height: Styling.Theme.barHeight

            Region {
                x: dropdownViewport.x
                y: dropdownViewport.y
                width: dropdownViewport.width
                height: root.dropdownRendered
                    ? Math.min(root.visualDropdownHeight,
                               Math.max(0, dropdownViewport.height + Math.min(0, dropdownContainer.y)))
                    : 0
            }
        }

        // Visible top bar
        GlassPanel {
            id: topBarGlass

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }

            height: Styling.Theme.barHeight
            radius: 0
            border.width: 0

            Rectangle {
                id: menuButton

                anchors.centerIn: parent
                width: 140
                height: 30
                radius: 10

                color: buttonArea.containsMouse ? "#33FFFFFF" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Liquid Shell"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 14
                }

                MouseArea {
                    id: buttonArea
                    anchors.fill: parent
                    hoverEnabled: true

                    onEntered: {
                        closeTimer.stop()
                        if (!root.suppressHoverOpen)
                            root.dropdownOpen = true
                    }

                    onExited: {
                        root.suppressHoverOpen = false
                        closeTimer.restart()
                    }

                    onClicked: root.dropdownOpen = !root.dropdownOpen
                }
            }
        }

        // ONE continuous material for the dropdown and both upper corner transitions.
        // This is behind the moving content, but outside the clipped viewport so the
        // 20px side curves can extend past the viewport's left and right boundaries.
        Canvas {
            id: unifiedDropdownGlass
            property real connectorRadius: 20
            property real bottomRadius: Styling.Theme.cornerRadius
            property color materialTint: Styling.Theme.glassBackground
            property real materialOpacity: 0.48 // Clear Glass; change to 0.88 for Frosted.
            readonly property real revealedHeight: Math.min(root.visualDropdownHeight,
                Math.max(0, dropdownViewport.height + Math.min(0, dropdownContainer.y)))

            x: dropdownViewport.x - connectorRadius
            y: dropdownViewport.y
            width: dropdownViewport.width + connectorRadius * 2
            height: root.visualDropdownHeight
            visible: root.dropdownRendered && revealedHeight > 0
            antialiasing: true

            onRevealedHeightChanged: requestPaint()
            onMaterialTintChanged: requestPaint()
            onMaterialOpacityChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                const r = connectorRadius
                const b = Math.min(bottomRadius, height / 2)
                const w = width
                const h = height
                const tint = materialTint
                ctx.clearRect(0, 0, w, h)
                ctx.save()
                ctx.beginPath()
                ctx.rect(0, 0, w, revealedHeight)
                ctx.clip()

                // The curves and the rectangular body are ONE filled path.
                // No adjacent translucent layers, therefore no double-alpha seam.
                ctx.beginPath()
                ctx.moveTo(0, 0)
                ctx.lineTo(w, 0)
                ctx.quadraticCurveTo(w - r, 0, w - r, r)
                ctx.lineTo(w - r, h - b)
                ctx.quadraticCurveTo(w - r, h, w - r - b, h)
                ctx.lineTo(r + b, h)
                ctx.quadraticCurveTo(r, h, r, h - b)
                ctx.lineTo(r, r)
                ctx.quadraticCurveTo(r, 0, 0, 0)
                ctx.closePath()
                ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, materialOpacity).toString()
                ctx.fill()
                ctx.restore()
            }
        }

        // Clip the moving panel at the underside of the bar, so it appears
        // to emerge from behind it without resizing the dashboard itself.
        Item {
            id: dropdownViewport
            width: 1300
            height: 850
            x: (bar.width - width) / 2
            y: Styling.Theme.barHeight
            clip: true
            visible: root.dropdownRendered

            Item {
                id: dropdownContainer
                anchors.left: parent.left
                width: parent.width
                height: parent.height
                y: -height

                CentralDropdown {
                    id: dropdownContent
                    anchors.fill: parent
                    // Keep the contents visible during the upward exit animation.
                    // dropdownRendered becomes false only after retraction finishes.
                    expanded: root.dropdownRendered
                }

                HoverHandler {
                    id: dropdownHoverHandler
                    onHoveredChanged: {
                        root.dropdownHovered = hovered
                        if (hovered)
                            closeTimer.stop()
                        else if (root.dropdownOpen)
                            closeTimer.restart()
                    }
                }
            }
        }

        // Single smooth reveal, with no overshoot or bounce.
        NumberAnimation {
            id: revealAnimation
            target: dropdownContainer
            property: "y"
            to: 0
            duration: 400
            easing.type: Easing.OutCubic
        }

        SequentialAnimation {
            id: retractAnimation
            NumberAnimation {
                target: dropdownContainer
                property: "y"
                to: -dropdownContainer.height
                duration: 250
                easing.type: Easing.InCubic
            }
            ScriptAction {
                script: {
                    if (!root.dropdownOpen) {
                        root.dropdownRendered = false
                        root.dropdownHovered = false
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            context: Qt.WindowShortcut
            enabled: root.dropdownOpen
            onActivated: root.dropdownOpen = false
        }
    }
}
