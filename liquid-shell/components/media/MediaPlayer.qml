

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../../theme" as Styling
import ".." as Components

Item {
    id: root

    property var selectedPlayer: null
    property string preferredPlayer: ""
    property bool manualSelection: false
    property bool playerMenuOpen: false
    property real playbackPosition: 0
    property bool seekingPreview: false
    property real previewPosition: 0
    // Keep the player-volume thumb responsive while the backend catches up.
    property bool adjustingPlayerVolume: false
    property real playerVolumePreview: 0
    // MPRIS has no mute property; remember the last nonzero volume per player.
    property var volumeBeforeMute: new Map()

    function togglePlayerMute() {
        const player = root.selectedPlayer
        if (!player || !player.volumeSupported) return
        const current = Math.max(0, Math.min(1, player.volume))
        if (current > 0.0001) {
            root.volumeBeforeMute.set(player, current)
            player.volume = 0
        } else {
            const saved = root.volumeBeforeMute.get(player)
            player.volume = saved !== undefined && saved > 0 ? saved : 0.5
        }
        root.adjustingPlayerVolume = false
    }

    function playerVolumeIcon() {
        if (!root.selectedPlayer || !root.selectedPlayer.volumeSupported)
            return "volume-off.svg"
        const volume = Math.round(playerVolumeSlider.value * 100)
        if (volume === 0) return "volume-off.svg"
        if (volume <= 25) return "volume.svg"
        if (volume <= 60) return "volume-1.svg"
        return "volume-2.svg"
    }

    function playerName(player) {
        return player.identity || player.desktopEntry || "Unknown Player"
    }

    function selectPlayer(player) {
        root.manualSelection = true
        root.preferredPlayer = player.desktopEntry || player.identity || ""
        root.playerMenuOpen = false
        root.updateSelection()
    }

    function useAutomaticSelection() {
        root.manualSelection = false
        root.preferredPlayer = ""
        root.playerMenuOpen = false
        root.updateSelection()
    }

    function updateSelection() {
        const players = Mpris.players.values
        let choice = null

        if (players.length === 0) {
            root.manualSelection = false
            root.preferredPlayer = ""
        } else {
            if (root.manualSelection) {
                for (const player of players) {
			if ((player.desktopEntry || player.identity || "") === root.preferredPlayer){
                        choice = player
                        break
                    }
                }
                if (!choice) {
                    root.manualSelection = false
                    root.preferredPlayer = ""
                }
            }

            if (!choice) {
                for (const player of players) {
                    if (player.playbackState === MprisPlaybackState.Playing) {
                        choice = player
                        break
                    }
                }
            }
            if (!choice) choice = players[0]
        }

        if (root.selectedPlayer !== choice) {
            root.seekingPreview = false
            root.selectedPlayer = choice
            root.adjustingPlayerVolume = false
            root.refreshPosition()
        }
    }

    function playerIcon(player) {
        if (!player) return Quickshell.iconPath("audio-x-generic")
        const entry = player.desktopEntry || ""
        return Quickshell.iconPath(entry, "audio-x-generic")
    }

    function formatTime(seconds) {
        if (!Number.isFinite(seconds) || seconds < 0)
            return "0:00"

        const total = Math.floor(seconds)
        const minutes = Math.floor(total / 60)
        const remaining = total % 60

        return minutes + ":" + String(remaining).padStart(2, "0")
    }

    function refreshPosition() {
        if (!root.selectedPlayer) {
            root.playbackPosition = 0
            root.seekingPreview = false
            return
        }

        if (root.seekingPreview) return
        root.selectedPlayer.positionChanged()
        root.playbackPosition = root.selectedPlayer.position
    }

    function toggleShuffle() {
        const player = root.selectedPlayer

        if (!player || !player.canControl || !player.shuffleSupported)
            return

        player.shuffle = !player.shuffle
    }

    function cycleRepeat() {
        const player = root.selectedPlayer

        if (!player || !player.canControl || !player.loopSupported)
            return

        if (player.loopState === MprisLoopState.None) {
            player.loopState = MprisLoopState.Playlist
        } else if (player.loopState === MprisLoopState.Playlist) {
            player.loopState = MprisLoopState.Track
        } else {
            player.loopState = MprisLoopState.None
        }
    }

    Connections {
        target: Mpris.players

        function onObjectInsertedPost() {
            root.updateSelection()
        }

        function onObjectRemovedPost() {
            root.updateSelection()
        }
    }

    Component.onCompleted: updateSelection()

    Timer {
        interval: 1000
        running: root.visible && root.selectedPlayer !== null
        repeat: true
        triggeredOnStart: true

        onTriggered: root.refreshPosition()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        Text {
            text: "Media Players"
            color: Styling.Theme.textPrimary
            font.pixelSize: 20
            font.bold: true
        }

        Text {
            text: Mpris.players.values.length + " player(s) detected"
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
        }

        // Compact player selector
        Rectangle {
            id: playerSelector
            Layout.fillWidth: true
            implicitHeight: 42
            radius: 10
            color: "#33FFFFFF"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Image {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    source: root.playerIcon(root.selectedPlayer)
                    fillMode: Image.PreserveAspectFit
                }
                Text {
                    Layout.fillWidth: true
                    text: root.selectedPlayer
                        ? root.playerName(root.selectedPlayer)
                          + (root.manualSelection ? "" : " (Auto)")
                        : "No media players"
                    color: Styling.Theme.textPrimary
                    elide: Text.ElideRight
                    font.pixelSize: 14
                }
                Text {
                    text: root.playerMenuOpen ? "▲" : "▼"
                    color: Styling.Theme.textSecondary
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.playerMenuOpen = !root.playerMenuOpen
            }
        }

        // Album artwork and metadata
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            spacing: 16

            Components.CircularAlbumArt {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 140
                artworkSource: root.selectedPlayer
                    ? (root.selectedPlayer.trackArtUrl || "")
                    : ""
                // The dedicated Media page intentionally has no rotation.
                spinning: false
                placeholderTextColor: Styling.Theme.textSecondary
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                Text {
                    Layout.fillWidth: true

                    text: root.selectedPlayer
                          ? (root.selectedPlayer.trackTitle || "Unknown Track")
                          : "No track selected"

                    color: Styling.Theme.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                Text {
                    Layout.fillWidth: true

                    text: root.selectedPlayer
                          ? (root.selectedPlayer.trackArtist || "Unknown Artist")
                          : ""

                    color: Styling.Theme.textSecondary
                    font.pixelSize: 15
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                Text {
                    Layout.fillWidth: true

                    text: root.selectedPlayer
                          ? (root.selectedPlayer.trackAlbum || "")
                          : ""

                    color: Styling.Theme.textSecondary
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }
            }
        }

        // Playback progress
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Components.GlassSlider {
                id: progressTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 34

                readonly property real duration: root.selectedPlayer
                    ? root.selectedPlayer.length : 0
                readonly property bool seekAvailable: root.selectedPlayer !== null
                    && duration > 0 && root.selectedPlayer.canSeek

                interactive: seekAvailable
                subdued: !seekAvailable
                value: duration > 0
                    ? Math.max(0, Math.min(1,
                        (root.seekingPreview ? root.previewPosition : root.playbackPosition) / duration))
                    : 0

                onMoved: fraction => {
                    if (!seekAvailable) return
                    root.seekingPreview = true
                    root.previewPosition = fraction * duration
                }

                onCommitted: fraction => {
                    if (!seekAvailable) {
                        root.seekingPreview = false
                        return
                    }
                    const player = root.selectedPlayer
                    const target = fraction * duration
                    player.position = target
                    root.playbackPosition = target
                    root.seekingPreview = false
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.seekingPreview ? root.previewPosition : root.playbackPosition)
                    color: Styling.Theme.textSecondary
                    font.pixelSize: 12
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: root.formatTime(
                        root.selectedPlayer
                            ? root.selectedPlayer.length
                            : 0
                    )

                    color: Styling.Theme.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        // Centered playback controls with independently right-aligned player volume.
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 56

            RowLayout {
                id: transportControls
                anchors.centerIn: parent
                spacing: 20
            Repeater {
                model: ["⏮", "▶", "⏭"]

                delegate: Rectangle {
                    required property int index
                    required property string modelData

                    property bool isPlayButton: index === 1

                    implicitWidth: isPlayButton ? 56 : 44
                    implicitHeight: isPlayButton ? 56 : 44
                    radius: width / 2
                    color: "#33FFFFFF"

                    Text {
                        anchors.centerIn: parent

                        text: isPlayButton && root.selectedPlayer
                              ? (root.selectedPlayer.playbackState
                                 === MprisPlaybackState.Playing
                                 ? "⏸" : "▶")
                              : modelData

                        color: Styling.Theme.textPrimary
                        font.pixelSize: isPlayButton ? 24 : 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (!root.selectedPlayer)
                                return

                            if (index === 0) {
                                root.selectedPlayer.previous()
                            } else if (index === 1) {
                                root.selectedPlayer.togglePlaying()
                            } else if (index === 2) {
                                root.selectedPlayer.next()
                            }
                        }
                    }
                }
            }
            }

            RowLayout {
                id: playerVolumeControls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 34
                    opacity: playerVolumeSlider.interactive ? 1 : 0.45

                    Image {
                        id: speakerIcon
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        sourceSize: Qt.size(52, 52)
                        // Relative to components/media/MediaPlayer.qml, not an absolute path.
                        source: Qt.resolvedUrl("../../assets/icons/Multimedia/" + root.playerVolumeIcon())
                        fillMode: Image.PreserveAspectFit
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: speakerIcon
                        source: speakerIcon
                        // Normalize dark SVG strokes before applying the theme tint.
                        brightness: 1.0
                        colorization: 1.0
                        colorizationColor: Styling.Theme.textPrimary
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: playerVolumeSlider.interactive
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.togglePlayerMute()
                    }
                }

                Components.GlassSlider {
                    id: playerVolumeSlider
                    Layout.preferredWidth: 175
                    Layout.preferredHeight: 34
                    readonly property bool volumeAvailable: root.selectedPlayer !== null
                        && root.selectedPlayer.volumeSupported
                    interactive: volumeAvailable
                    subdued: !volumeAvailable
                    value: root.adjustingPlayerVolume
                        ? root.playerVolumePreview
                        : (volumeAvailable ? Math.max(0, Math.min(1, root.selectedPlayer.volume)) : 0)

                    onMoved: fraction => {
                        if (!volumeAvailable) return
                        root.adjustingPlayerVolume = true
                        root.playerVolumePreview = fraction
                        if (fraction > 0) root.volumeBeforeMute.set(root.selectedPlayer, fraction)
                        root.selectedPlayer.volume = fraction
                    }
                    onCommitted: fraction => {
                        if (!volumeAvailable) {
                            root.adjustingPlayerVolume = false
                            return
                        }
                        root.selectedPlayer.volume = fraction
                        root.adjustingPlayerVolume = false
                    }
                }

                Text {
                    Layout.preferredWidth: 38
                    horizontalAlignment: Text.AlignRight
                    text: playerVolumeSlider.volumeAvailable
                        ? Math.round(playerVolumeSlider.value * 100) + "%"
                        : "--%"
                    color: Styling.Theme.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        // Shuffle and repeat
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 32

            Rectangle {
                implicitWidth: 100
                implicitHeight: 36
                radius: 10

                property bool supported: root.selectedPlayer
                    && root.selectedPlayer.canControl
                    && root.selectedPlayer.shuffleSupported

                color: root.selectedPlayer && root.selectedPlayer.shuffle
                       ? "#44FFFFFF"
                       : "#16FFFFFF"

                opacity: supported ? 1.0 : 0.4

                Text {
                    anchors.centerIn: parent
                    text: "Shuffle"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.supported
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleShuffle()
                }
            }

            Rectangle {
                implicitWidth: 120
                implicitHeight: 36
                radius: 10

                property bool supported: root.selectedPlayer
                    && root.selectedPlayer.canControl
                    && root.selectedPlayer.loopSupported

                color: root.selectedPlayer
                       && root.selectedPlayer.loopState !== MprisLoopState.None
                       ? "#44FFFFFF"
                       : "#16FFFFFF"

                opacity: supported ? 1.0 : 0.4

                Text {
                    anchors.centerIn: parent

                    text: {
                        if (!root.selectedPlayer)
                            return "Repeat Off"

                        switch (root.selectedPlayer.loopState) {
                        case MprisLoopState.Playlist:
                            return "Repeat All"
                        case MprisLoopState.Track:
                            return "Repeat One"
                        default:
                            return "Repeat Off"
                        }
                    }

                    color: Styling.Theme.textPrimary
                    font.pixelSize: 13
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: parent.supported
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cycleRepeat()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
    // Floating menu: does not consume space in the main ColumnLayout.
    Rectangle {
        id: playerMenu
        visible: root.playerMenuOpen
        z: 100
        x: playerSelector.mapToItem(root, 0, 0).x
        y: playerSelector.mapToItem(root, 0, playerSelector.height).y + 4
        width: playerSelector.width
        implicitHeight: menuContent.implicitHeight + 12
        radius: 10
        color: Styling.Theme.glassBackground
        border.width: 1
        border.color: Styling.Theme.glassBorder

        ColumnLayout {
            id: menuContent
            anchors.fill: parent
            anchors.margins: 6
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                color: !root.manualSelection ? "#44FFFFFF" : "#16FFFFFF"
                Text {
                    anchors.centerIn: parent
                    text: "Auto-select playing player"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 13
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.useAutomaticSelection()
                }
            }

            Repeater {
                model: Mpris.players
                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 8
                    color: root.selectedPlayer === modelData ? "#44FFFFFF" : "#16FFFFFF"

                    Connections {
                        target: modelData
                        function onPlaybackStateChanged() {
                            if (!root.manualSelection) root.updateSelection()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10
                        Image {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            source: root.playerIcon(modelData)
                            fillMode: Image.PreserveAspectFit
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.playerName(modelData)
                            color: Styling.Theme.textPrimary
                            font.pixelSize: 13
                        }
                        Text {
                            text: modelData.playbackState === MprisPlaybackState.Playing
                                ? "Playing" : "Paused / Stopped"
                            color: Styling.Theme.textSecondary
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectPlayer(modelData)
                    }
                }
            }
        }
    }

}

