import QtQuick
import "../../theme" as Styling
import ".." as Components

Rectangle {
    id: card

    default property alias content: contentArea.data

    property int padding: 16
    property url glassAsset: ""
    property url glassAssetLight: ""
    property url glassAssetDark: ""

    color: "transparent"
    border.width: 0
	Components.GlassPanel {
    		anchors.fill: parent
    		z: -1
            reflectionAsset: card.glassAsset
            reflectionAssetLight: card.glassAssetLight
            reflectionAssetDark: card.glassAssetDark
}

    Item {
        id: contentArea

        anchors.fill: parent
        anchors.margins: card.padding
    }
}

