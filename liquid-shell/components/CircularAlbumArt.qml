import QtQuick
import QtQuick.Effects

// Reusable circular album art. Animation is opt-in; the Media tab stays static.
Item {
    id: root

    property url artworkSource: ""
    property bool spinning: false
    property int revolutionDuration: 15000
    property color placeholderColor: "#18000000"
    property color placeholderTextColor: "#999999"

    // A circle requires an alpha mask: Rectangle.clip only clips rectangles.
    Image {
        id: artworkImage
        anchors.fill: parent
        source: root.artworkSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        visible: false
        layer.enabled: true
    }

    Rectangle {
        id: circularMask
        anchors.fill: parent
        radius: width / 2
        color: "white"
        visible: false
        layer.enabled: true
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.placeholderColor
        visible: artworkImage.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: "No Artwork"
            color: root.placeholderTextColor
            font.pixelSize: 12
            visible: parent.visible
        }
    }

    MultiEffect {
        id: roundedArtwork
        anchors.fill: parent
        source: artworkImage
        maskEnabled: true
        maskSource: circularMask
        autoPaddingEnabled: false
        visible: artworkImage.status === Image.Ready
        transformOrigin: Item.Center

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: root.revolutionDuration
            loops: Animation.Infinite
            running: true
            paused: !root.spinning || !roundedArtwork.visible || !root.visible
        }
    }
}
