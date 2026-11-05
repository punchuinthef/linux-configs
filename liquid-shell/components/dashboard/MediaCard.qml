import QtQuick
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../../theme" as Styling
import ".." as Components

DashboardCard {
    id: root

    
    property var selectedPlayer: null
    property int streamRevision: 0

    readonly property var selectedAudioNode: {
        // Track observer changes and the active MPRIS player.
        const revision = root.streamRevision
        const player = root.selectedPlayer
        return root.findAudioNode(player)
}

	

	onSelectedAudioNodeChanged: {
    console.log("[Liquid Shell] Selected audio node:",
                selectedAudioNode ? selectedAudioNode.name : "none")

}

    readonly property real playerVolume: root.selectedAudioNode && root.selectedAudioNode.audio
        ? root.selectedAudioNode.audio.volume
        : 0

    function findAudioNode(player) {
        if (!player)
            return null

        const identity = String(player.identity || "").toLowerCase()
        const busName = String(player.dbusName || "").toLowerCase()
        let playerName = ""

        if (identity.includes("spotify") || busName.includes("spotify"))
            playerName = "spotify"
        else if (identity.includes("elisa") || busName.includes("elisa"))
            playerName = "elisa"
        else
            return null

        let match = null

        for (let i = 0; i < audioObservers.count; i++) {
            const observer = audioObservers.itemAt(i)
            if (!observer || !observer.modelData)
                continue

            const node = observer.modelData
            if (!node.ready || !node.isStream || !node.audio)
                continue

            const props = node.properties || {}
            const appName = String(props["application.name"] || "").toLowerCase()
            const appId = String(props["application.id"] || "").toLowerCase()
            const matches = appName === playerName ||
                (playerName === "elisa" && appId === "org.kde.elisa")

            if (!matches)
                continue

            // Never guess when multiple streams match.
            if (match)
                return null

            match = node
        }

        return match
    }

    function setPlayerVolume(value) {
        const node = root.selectedAudioNode
        if (!node || !node.audio)
            return

        node.audio.volume = Math.max(0, Math.min(1, value))
    }

    function updateSelection() {
        const players = Mpris.players.values
        let choice = null

        for (const player of players) {
            if (player.playbackState === MprisPlaybackState.Playing) {
                choice = player
                break
            }
        }

        if (!choice && players.length > 0)
            choice = players[0]

        root.selectedPlayer = choice
    }

    Connections {
        target: Mpris.players

        function onObjectInsertedPost() { root.updateSelection() }
        function onObjectRemovedPost() { root.updateSelection() }
    }

    Repeater {
        model: Mpris.players

        delegate: Item {
            id: playerObserver
            required property var modelData
            width: 0
            height: 0
            visible: false

            Connections {
                target: playerObserver.modelData
                function onPlaybackStateChanged() { root.updateSelection() }
            }
        }
    }

    Repeater {
        id: audioObservers
        model: Pipewire.nodes

        delegate: Item {
            id: audioObserver
            required property var modelData
            width: 0
            height: 0
            visible: false

            PwObjectTracker {
                objects: [audioObserver.modelData]
            }

            Connections {
                target: audioObserver.modelData
                function onReadyChanged() { root.streamRevision++ }
            }

            Component.onCompleted: root.streamRevision++
        }

        onItemAdded: root.streamRevision++
        onItemRemoved: root.streamRevision++
    }

Component.onCompleted: {
    updateSelection()

    console.log("[Liquid Shell] Media info height:", mediaInfo.implicitHeight)
    console.log("[Liquid Shell] Volume controls height:", volumeControls.implicitHeight)
    console.log("[Liquid Shell] Card height:", root.height)
}
    Column {
	    id: mediaInfo    
	anchors {
        top: parent.top
        left: parent.left
        right: parent.right
	
	}
        spacing: 14

        Text {
            width: parent.width
            text: "NOW PLAYING"
            horizontalAlignment: Text.AlignHCenter
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
        }

        Components.CircularAlbumArt {
            width: Math.min(parent.width, 280)
            height: width
            anchors.horizontalCenter: parent.horizontalCenter
            artworkSource: root.selectedPlayer
                ? (root.selectedPlayer.trackArtUrl || "")
                : ""
            spinning: root.selectedPlayer !== null
                && root.selectedPlayer.playbackState === MprisPlaybackState.Playing
            placeholderTextColor: Styling.Theme.textSecondary
        }

        Text {
            width: parent.width
            text: root.selectedPlayer
                ? (root.selectedPlayer.trackTitle || "Unknown Track")
                : "Nothing playing"
            color: Styling.Theme.textPrimary
            font.pixelSize: 20
            font.bold: true
            elide: Text.ElideRight
        }

	Text {
    width: parent.width

    text: {
        if (!root.selectedPlayer)
            return "Open a media player to get started"

        const artist = root.selectedPlayer.trackArtist || "Unknown Artist"
        const album = root.selectedPlayer.trackAlbum || ""

        return album ? artist + " / " + album : artist
    }

    color: Styling.Theme.textSecondary
    font.pixelSize: 14
    elide: Text.ElideRight
    maximumLineCount: 1
}
}

	
Row {
    id: playbackControls

    anchors {
        top: mediaInfo.bottom
        topMargin: 18
        horizontalCenter: parent.horizontalCenter
    }

    spacing: 12

    Repeater {
        model: ["previous", "toggle", "next"]

        delegate: Rectangle {
            id: playbackButton

            required property string modelData

            readonly property var player: root.selectedPlayer

            readonly property bool available: {
                if (!player)
                    return false

                if (modelData === "previous")
                    return player.canGoPrevious

                if (modelData === "next")
                    return player.canGoNext

                return player.canTogglePlaying
            }

            width: modelData === "toggle" ? 48 : 40
            height: width
            radius: width / 2
	    anchors.verticalCenter: parent.verticalCenter

            color: Styling.Theme.glassBorder

            opacity: available ? 1.0 : 0.35

            readonly property string iconFile: modelData === "previous" ? "skip-back.svg"
                : modelData === "next" ? "skip-forward.svg"
                : playbackButton.player && playbackButton.player.isPlaying ? "pause.svg" : "play.svg"

            Image {
                id: playbackIcon
                anchors.centerIn: parent
                width: 20
                height: 20
                source: Qt.resolvedUrl("../../assets/icons/Multimedia/" + playbackButton.iconFile)
                sourceSize: Qt.size(40, 40)
                fillMode: Image.PreserveAspectFit
                visible: false
            }

            MultiEffect {
                anchors.fill: playbackIcon
                source: playbackIcon
                brightness: 1.0
                colorization: 1.0
                colorizationColor: Styling.Theme.textPrimary
            }

            MouseArea {
                anchors.fill: parent

                enabled: playbackButton.available

                cursorShape: enabled
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor

                onClicked: {
                    const player = root.selectedPlayer

                    if (!player)
                        return

                    switch (playbackButton.modelData) {
                    case "previous":
                        player.previous()
                        break

                    case "toggle":
                        player.togglePlaying()
                        break

                    case "next":
                        player.next()
                        break
                    }
                }
            }
        }
    }
}
	
	

     
   
Column {
    id: volumeControls

    anchors {
        top: playbackControls.bottom
        topMargin: 18
        left: parent.left
        right: parent.right
    }

    spacing: 10

    readonly property bool hasStream: root.selectedAudioNode !== null

    Row {
        width: parent.width

        Text {
            id: volumeHeading
            text: "VOLUME"
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
        }

        Item {
            width: Math.max(0, parent.width - volumeLabel.width - volumeHeading.width)
            height: 1
        }

        Text {
            id: volumeLabel
            text: volumeControls.hasStream
                ? Math.round(root.playerVolume * 100) + "%"
                : "--%"
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
        }
    }

    Components.GlassSlider {
        id: volumeSlider
        width: parent.width
        height: 34
        value: root.playerVolume
        interactive: volumeControls.hasStream
        onMoved: value => root.setPlayerVolume(value)
    }
}

}
