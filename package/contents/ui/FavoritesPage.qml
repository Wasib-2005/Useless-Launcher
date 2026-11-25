// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    spacing: Kirigami.Units.smallSpacing

    function focusContent() {
        favGrid.forceActiveFocus()
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading {
            text: i18n("Favourites")
            level: 3
            color: root.effectiveTextColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: favGrid.count > 0
            text: String(favGrid.count)
            monospace: true
        }
        MenuButton {}
    }

    AppGridView {
        id: favGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: rootModel.favoritesModel
        reorderable: true
        emptyIcon: "favorite"
        emptyText: i18n("No favourites pinned yet. Right-click any app or drag it onto the top ribbon to pin it.")
    }
}
