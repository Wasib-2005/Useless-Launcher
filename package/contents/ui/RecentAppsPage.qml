// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker

// Recently used applications (KActivityStats history, same source Kickoff uses)
ColumnLayout {
    spacing: Kirigami.Units.smallSpacing

    function focusContent() {
        recentGrid.forceActiveFocus()
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading {
            text: i18n("Recent apps")
            level: 3
            color: root.effectiveTextColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: recentGrid.count > 0
            text: String(recentGrid.count)
            monospace: true
        }
        MenuButton {}
    }

    AppGridView {
        id: recentGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        emptyIcon: "view-history"
        emptyText: i18n("Launch an app and your recent history will appear here.")
        model: Kicker.RecentUsageModel {
            favoritesModel: rootModel.favoritesModel
            shownItems: Kicker.RecentUsageModel.OnlyApps
        }
    }
}
