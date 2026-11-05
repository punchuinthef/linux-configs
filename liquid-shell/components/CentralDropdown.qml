import QtQuick
import QtQuick.Layouts
import "../theme" as Styling
import "dashboard" as DashboardComponents
import "media" as MediaComponents

Item {
    id: dropdown

    property bool expanded: false
    property int currentTab: 0
    width: 700
    height: expanded ? 550 : 0
    visible: expanded

    Item {
        anchors.fill: parent
        // Background is painted once by TopBar.qml, including both curved corners.

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // Minimal navigation: no background track, retain the moving selection indicator.
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    id: navigationTrack
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    radius: height / 2
                    color: "transparent"
                    border.width: 0

                    // Flat selected-tab indicator. It compresses to an orb while travelling,
                    // then expands around the destination label.
                    Rectangle {
                        id: selectionCapsule
                        z: 0
                        property real capsulePadding: 8
                        property real fullWidth: navigationTrack.labelWidthFor(dropdown.currentTab) + 2 * capsulePadding
                        property real fullHeight: navigationTrack.height - 4
                        property real orbSize: navigationTrack.height - 4
                        property real destinationX: navigationTrack.labelCenterFor(dropdown.currentTab) - fullWidth / 2
                        property real centerX: destinationX + fullWidth / 2
                        x: centerX - width / 2
                        y: 2
                        width: fullWidth
                        height: fullHeight
                        radius: height / 2
                        color: Qt.rgba(Styling.Theme.textPrimary.r,
                                       Styling.Theme.textPrimary.g,
                                       Styling.Theme.textPrimary.b, 0.15)
                        border.width: 1
                        border.color: Qt.rgba(Styling.Theme.textPrimary.r,
                                              Styling.Theme.textPrimary.g,
                                              Styling.Theme.textPrimary.b, 0.42)
                    }

                    // One uninterrupted center movement; the shape morphs in parallel.
                    ParallelAnimation {
                        id: capsuleMorph
                        NumberAnimation {
                            id: travelCenter
                            target: selectionCapsule
                            property: "centerX"
                            duration: 400
                            easing.type: Easing.InOutSine
                        }
                        SequentialAnimation {
                            NumberAnimation {
                                id: shrinkWidth
                                target: selectionCapsule
                                property: "width"
                                duration: 115
                                easing.type: Easing.OutCubic
                            }
                            PauseAnimation { duration: 145 }
                            NumberAnimation {
                                id: expandWidth
                                target: selectionCapsule
                                property: "width"
                                duration: 140
                                easing.type: Easing.InOutCubic
                            }
                        }
                    }

                    // Measure the actual text, not the full evenly spaced tab.
                    function labelWidthFor(index) {
                        const tab = tabRepeater.itemAt(index)
                        return tab ? tab.labelWidth : 0
                    }

                    function labelCenterFor(index) {
                        const tab = tabRepeater.itemAt(index)
                        return tab ? tab.x + tab.width / 2 : (index + 0.5) * width / 4
                    }

                    function snapToCurrentTab() {
                        if (capsuleMorph.running) return
                        selectionCapsule.width = labelWidthFor(dropdown.currentTab) + 2 * selectionCapsule.capsulePadding
                        selectionCapsule.centerX = labelCenterFor(dropdown.currentTab)
                        selectionCapsule.height = selectionCapsule.fullHeight
                        selectionCapsule.y = 2
                    }

                    Component.onCompleted: Qt.callLater(snapToCurrentTab)

                    function selectTab(index) {
                        if (dropdown.currentTab === index)
                            return

                        capsuleMorph.stop()

                        const targetWidth = navigationTrack.labelWidthFor(index) + 2 * selectionCapsule.capsulePadding
                        const targetCenter = navigationTrack.labelCenterFor(index)
                        const orb = selectionCapsule.orbSize

                        travelCenter.from = selectionCapsule.centerX
                        travelCenter.to = targetCenter
                        shrinkWidth.from = selectionCapsule.width
                        shrinkWidth.to = orb
                        expandWidth.from = orb
                        expandWidth.to = targetWidth

                        dropdown.currentTab = index
                        // Bold selected text may change its measured width.
                        expandWidth.to = navigationTrack.labelWidthFor(index) + 2 * selectionCapsule.capsulePadding
                        travelCenter.to = navigationTrack.labelCenterFor(index)
                        capsuleMorph.start()
                    }

                    // Re-align the indicator if the dropdown changes size.
                    onWidthChanged: {
                        if (!capsuleMorph.running) {
                            Qt.callLater(snapToCurrentTab)
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        z: 1

                        Repeater {
                            id: tabRepeater
                            model: ["Dashboard", "Media", "Storage", "Emojis"]

                            delegate: Item {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readonly property real labelWidth: tabLabel.implicitWidth

                                Text {
                                    id: tabLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: dropdown.currentTab === index
                                           ? Styling.Theme.textPrimary
                                           : Styling.Theme.textSecondary
                                    font.pixelSize: 13
                                    font.bold: dropdown.currentTab === index

                                    Behavior on color {
                                        ColorAnimation { duration: 180 }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        navigationTrack.selectTab(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Content area
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                DashboardComponents.Dashboard {
                    anchors.fill: parent
                    visible: dropdown.currentTab === 0
                }

                MediaComponents.MediaPlayer {
                    anchors.fill: parent
                    visible: dropdown.currentTab === 1
                }

                EmojiPicker {
                    anchors.fill: parent
                    visible: dropdown.currentTab === 3
                }

                DashboardComponents.Storage {
                    anchors.fill: parent
                    visible: dropdown.currentTab === 2
                    active: dropdown.expanded && dropdown.currentTab === 2
                }
            }
        }
    }

}
