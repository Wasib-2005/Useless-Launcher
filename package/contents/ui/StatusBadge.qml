// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Sleek compact pill badge used for HUD telemetry, keyboard shortcut hints,
// and drive/status tags. Adapts cleanly across all Future themes.
Rectangle {
    id: badge

    property string text: ""
    property string iconName: ""
    property bool accentTone: false
    property bool monospace: false
    property real textOpacity: 0.88

    implicitWidth: row.implicitWidth + Kirigami.Units.smallSpacing * 2.2
    implicitHeight: Math.max(Kirigami.Units.gridUnit * 1.15, row.implicitHeight + 4)
    radius: root.pillRadius

    color: badge.accentTone
        ? root.withAlpha(root.effectiveAccent, root.isDark ? 0.16 : 0.12)
        : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.075 : 0.05)
    border.width: 1
    border.color: badge.accentTone
        ? root.withAlpha(root.effectiveAccent, root.isCyber ? 0.55 : 0.35)
        : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.12 : 0.09)

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Math.max(3, Math.round(Kirigami.Units.smallSpacing * 0.6))

        Kirigami.Icon {
            visible: badge.iconName.length > 0
            source: badge.iconName
            Layout.preferredWidth: Kirigami.Units.iconSizes.small * 0.72
            Layout.preferredHeight: Layout.preferredWidth
            isMask: true
            color: badge.accentTone ? root.effectiveAccent : root.effectiveTextColor
            opacity: badge.textOpacity
        }

        QQC2.Label {
            text: badge.text
            color: badge.accentTone ? root.effectiveAccent : root.effectiveTextColor
            opacity: badge.textOpacity
            font.pointSize: Math.max(7, Kirigami.Theme.smallFont.pointSize - 1)
            font.family: badge.monospace ? "monospace" : Kirigami.Theme.smallFont.family
            font.weight: badge.accentTone ? Font.Medium : Font.Normal
        }
    }
}
