import QtQuick
import "../theme" as Styling

// Plain themed dropdown surface. Filename and glassMode remain for compatibility.
Rectangle {
    id: canvasSurface

    // Preserve existing caller bindings; this now controls opacity only.
    property string glassMode: "frosted"
    readonly property bool clearMode: glassMode === "clear"

    color: Qt.rgba(
        Styling.Theme.panelBackground.r,
        Styling.Theme.panelBackground.g,
        Styling.Theme.panelBackground.b,
        clearMode ? 0.48 : Styling.Theme.panelBackground.a
    )
    radius: Styling.Theme.cornerRadius
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: radius
    bottomRightRadius: radius
    border.width: 0
}
