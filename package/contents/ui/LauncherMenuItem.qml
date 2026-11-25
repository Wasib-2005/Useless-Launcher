// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Styled MenuItem matching Future popup glass highlights.
QQC2.MenuItem {
    id: menuItem

    background: Rectangle {
        implicitHeight: Kirigami.Units.gridUnit * 1.8
        radius: Math.max(4, Math.round(root.cardRadius * 0.72))
        color: menuItem.highlighted ? root.effectiveTileHoverColor : "transparent"
        border.width: menuItem.highlighted ? 1 : 0
        border.color: menuItem.highlighted
            ? root.withAlpha(root.effectiveAccent, 0.42)
            : "transparent"
    }
}
