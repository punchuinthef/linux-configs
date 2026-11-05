import QtQuick
import "../theme" as Styling

// Neutral themed container. The filename is retained for import compatibility.
Rectangle {
    id: panel

    property bool connectedTop: false

    // Compatibility-only properties for callers using the old reflection API.
    // They intentionally have no visual effect.
    property url reflectionAsset: ""
    property url reflectionAssetLight: ""
    property url reflectionAssetDark: ""

    color: Styling.Theme.panelBackground
    radius: Styling.Theme.cornerRadius
    topLeftRadius: connectedTop ? 0 : radius
    topRightRadius: connectedTop ? 0 : radius
    bottomLeftRadius: radius
    bottomRightRadius: radius
    border.width: Styling.Theme.borderWidth
    border.color: Styling.Theme.panelBorder
}
