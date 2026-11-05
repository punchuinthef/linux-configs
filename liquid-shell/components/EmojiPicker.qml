import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import "../theme" as Styling

Item {
    id: picker
    property var allEmojis: []
    property string selectedGroup: "All"
    property string query: ""
    property string statusMessage: "Loading emojis…"
    property var recentEmojiCodes: []
    property var favouriteEmojiCodes: []
    readonly property int maxRecents: 40
    property var groups: ["All", "Recents", "Favourites", "Smileys & Emotion", "People & Body", "Animals & Nature", "Food & Drink", "Travel & Places", "Activities", "Objects", "Symbols", "Flags"]

    implicitWidth: 420
    implicitHeight: 430

    // Settings is backed by Qt's application settings, not a custom external process.
    // Persist emoji strings (rather than database indices) so updates won't break the lists.
    Settings {
        id: emojiSettings
        category: "EmojiPicker"
        property string recentsJson: "[]"
        property string favouritesJson: "[]"
    }

    function readStoredList(value) {
        try {
            const parsed = JSON.parse(value);
            return Array.isArray(parsed) ? parsed.filter(function(code) { return typeof code === "string"; }) : [];
        } catch (error) {
            return [];
        }
    }

    Component.onCompleted: {
        recentEmojiCodes = readStoredList(emojiSettings.recentsJson);
        favouriteEmojiCodes = readStoredList(emojiSettings.favouritesJson);
    }

    function isFavourite(code) {
        return favouriteEmojiCodes.indexOf(code) !== -1;
    }

    function toggleFavourite(code) {
        const updated = favouriteEmojiCodes.slice();
        const index = updated.indexOf(code);
        if (index !== -1) {
            updated.splice(index, 1);
            statusMessage = "Removed " + code + " from Favourites";
        } else {
            updated.unshift(code);
            statusMessage = "Added " + code + " to Favourites";
        }
        favouriteEmojiCodes = updated;
        emojiSettings.favouritesJson = JSON.stringify(updated);
    }

    function recordRecent(code) {
        const updated = recentEmojiCodes.filter(function(item) { return item !== code; });
        updated.unshift(code);
        if (updated.length > maxRecents)
            updated.length = maxRecents;
        recentEmojiCodes = updated;
        emojiSettings.recentsJson = JSON.stringify(updated);
    }

    // Reuse entries from the existing emoji database to keep search and names intact.
    function entriesInOrder(codes) {
        const byCode = {};
        for (let i = 0; i < allEmojis.length; i++)
            byCode[allEmojis[i].emoji] = allEmojis[i];
        return codes.map(function(code) { return byCode[code]; }).filter(function(entry) { return entry !== undefined; });
    }

    readonly property var filteredEmojis: {
        const pool = selectedGroup === "Recents" ? entriesInOrder(recentEmojiCodes)
                   : selectedGroup === "Favourites" ? entriesInOrder(favouriteEmojiCodes)
                   : allEmojis;
        const term = query.trim().toLowerCase();
        return pool.filter(function(entry) {
            const groupMatches = selectedGroup === "All" || selectedGroup === "Recents" || selectedGroup === "Favourites" || entry.group === selectedGroup;
            return groupMatches && (term.length === 0 || entry.name.toLowerCase().indexOf(term) !== -1 || entry.emoji.indexOf(term) !== -1);
        });
    }

    FileView {
        id: emojiFile
        path: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/liquid-shell/emoji/emojis.json"
        onLoaded: {
            try {
                const database = JSON.parse(text());
                if (!Array.isArray(database.emojis)) throw new Error("Missing emojis array");
                picker.allEmojis = database.emojis;
                picker.statusMessage = "";
            } catch (error) {
                picker.statusMessage = "Emoji database error: " + error;
            }
        }
        onLoadFailed: picker.statusMessage = "Cannot read emojis.json. Run update-emojis.py first."
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Styling.Theme.surface ?? "#24242b"
        border.width: 1
        border.color: Styling.Theme.textPrimary
        opacity: 0.97
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Emoji picker"
                font.pixelSize: 16
                font.bold: true
                color: Styling.Theme.textPrimary
                Layout.fillWidth: true
            }
            Text {
                text: picker.filteredEmojis.length + " emojis"
                font.pixelSize: 11
                color: Styling.Theme.textPrimary
                opacity: 0.7
            }
        }

        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Search emojis…"
            onTextChanged: picker.query = text
            font.pixelSize: 13
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            Row {
                spacing: 6
                Repeater {
                    model: picker.groups
                    delegate: Rectangle {
                        required property string modelData
                        width: categoryLabel.implicitWidth + 20
                        height: 28
                        radius: 9
                        color: picker.selectedGroup === modelData ? "#44FFFFFF" : "#1AFFFFFF"
                        Text {
                            id: categoryLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: Styling.Theme.textPrimary
                            font.pixelSize: 11
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: picker.selectedGroup = modelData
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: emojiGrid
                anchors.fill: parent
                clip: true
                cellWidth: 52
                cellHeight: 52
                model: picker.filteredEmojis
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                delegate: Item {
                    required property var modelData
                    width: emojiGrid.cellWidth
                    height: emojiGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 10
                        color: emojiMouse.containsMouse ? "#33FFFFFF" : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        text: modelData.emoji
                        font.family: "Noto Color Emoji"
                        font.pixelSize: 27
                    }
                    MouseArea {
                        id: emojiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                emojiMenu.popup();
                                return;
                            }
                            Quickshell.execDetached(["wl-copy", "--", modelData.emoji]);
                            picker.recordRecent(modelData.emoji);
                            picker.statusMessage = "Copied " + modelData.emoji + " — " + modelData.name;
                        }
                        ToolTip.visible: containsMouse && !emojiMenu.visible
                        ToolTip.delay: 550
                        ToolTip.timeout: 4000
                        ToolTip.text: modelData.name
                    }
                    Menu {
                        id: emojiMenu
                        MenuItem {
                            text: picker.isFavourite(modelData.emoji) ? "Remove from Favourites" : "Add to Favourites"
                            onTriggered: picker.toggleFavourite(modelData.emoji)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: picker.allEmojis.length === 0 || picker.filteredEmojis.length === 0
                text: picker.allEmojis.length === 0 ? picker.statusMessage
                    : picker.selectedGroup === "Recents" && picker.recentEmojiCodes.length === 0 ? "No recent emojis yet — click one to copy it"
                    : picker.selectedGroup === "Favourites" && picker.favouriteEmojiCodes.length === 0 ? "No favourites yet — right-click an emoji to save it"
                    : "No matching emojis"
                color: Styling.Theme.textPrimary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Text {
            Layout.fillWidth: true
            text: picker.statusMessage || "Left-click to copy · Right-click to favourite"
            color: Styling.Theme.textPrimary
            opacity: 0.75
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
