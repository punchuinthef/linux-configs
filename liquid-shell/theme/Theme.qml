pragma Singleton

import QtQuick

QtObject {
    id: theme

    // Wallpaper-derived palette. These remain reactive to Matugen.
    readonly property color primary: MatugenColors.primary
    readonly property color surface: MatugenColors.surface
    readonly property color textPrimary: MatugenColors.surfaceText
    readonly property color textSecondary: MatugenColors.surfaceTextVariant

    // Neutral surface tokens for the next visual design.
    readonly property color panelBackground: Qt.rgba(
        MatugenColors.surfaceContainer.r,
        MatugenColors.surfaceContainer.g,
        MatugenColors.surfaceContainer.b,
        0.88
    )
    readonly property color panelBorder: Qt.rgba(
        MatugenColors.outline.r,
        MatugenColors.outline.g,
        MatugenColors.outline.b,
        0.35
    )

    // Compatibility aliases: other QML files may still reference these names.
    // Remove only after all call sites have been migrated.
    readonly property color glassBackground: panelBackground
    readonly property color glassBorder: panelBorder

    readonly property int cornerRadius: 16
    readonly property int borderWidth: 1
    readonly property int contentPadding: 8
    readonly property int barHeight: 36
}
