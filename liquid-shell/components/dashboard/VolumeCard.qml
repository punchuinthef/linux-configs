import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Pipewire
import ".." as Components
import "../../theme" as Styling

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool hasAudio: sink !== null && sink.audio !== null
    readonly property real volume: hasAudio ? sink.audio.volume : 0
    readonly property bool muted: hasAudio ? sink.audio.muted : false
    readonly property string iconName: muted || volume <= 0 ? "volume-off.svg"
                                      : volume <= 0.25 ? "volume.svg"
                                      : volume <= 0.60 ? "volume-1.svg"
                                      : "volume-2.svg"

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    function setVolume(value) {
        if (hasAudio)
            sink.audio.volume = Math.max(0, Math.min(1, value))
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 15

        Row {
            width: parent.width
            spacing: 6

            Text {
                text: root.muted ? "MUTED" : "VOLUME"
                color: Styling.Theme.textPrimary
                font.pixelSize: 12
                font.bold: true
            }
            Item { width: Math.max(0, parent.width - percentage.width - 72); height: 1 }
            Text {
                id: percentage
                text: root.hasAudio ? Math.round(root.volume * 100) + "%" : "--%"
                color: Styling.Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
            }
        }

        Row {
            width: parent.width
            spacing: 10

            Item {
                width: 24
                height: 34
                opacity: root.hasAudio ? 1 : 0.4

                Image {
                    id: speakerIcon
                    anchors.centerIn: parent
                    width: 21
                    height: 21
                    source: Qt.resolvedUrl("../../assets/icons/Multimedia/" + root.iconName)
                    fillMode: Image.PreserveAspectFit
                    sourceSize: Qt.size(42, 42)
                    visible: false
                }

                MultiEffect {
                    anchors.fill: speakerIcon
                    source: speakerIcon
                    brightness: 1.0
                    colorization: 1.0
                    colorizationColor: Styling.Theme.textPrimary
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.hasAudio
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.sink.audio.muted = !root.sink.audio.muted
                }
            }

            Components.GlassSlider {
                width: Math.max(0, parent.width - 34)
                height: 34
                value: root.volume
                interactive: root.hasAudio
                subdued: root.muted
                onMoved: value => root.setVolume(value)
            }
        }
    }
}
