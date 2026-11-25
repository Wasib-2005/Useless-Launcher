// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2

// Slim Future vertical scrollbar shared across all grids and lists.
QQC2.ScrollBar {
    id: sb
    policy: QQC2.ScrollBar.AsNeeded

    contentItem: Rectangle {
        implicitWidth: sb.hovered || sb.pressed ? 6 : 4
        implicitHeight: 28
        radius: width / 2
        color: sb.pressed
            ? root.effectiveAccent
            : (sb.hovered
                ? root.withAlpha(root.effectiveAccent, 0.72)
                : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.24 : 0.20))
        opacity: sb.active ? 1.0 : 0.35
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on implicitWidth { NumberAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    background: Item { implicitWidth: 6 }
}
