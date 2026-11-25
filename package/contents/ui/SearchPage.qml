// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// KRunner results rendered as Future list cards with active Enter hint
ColumnLayout {
    id: searchPage
    spacing: Kirigami.Units.smallSpacing

    function focusResults() {
        resultsList.forceActiveFocus()
        if (resultsList.count > 0) { resultsList.currentIndex = 0 }
    }

    function runFirst() {
        if (resultsList.count > 0) {
            resultsList.itemAtIndex(0)?.run()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            text: i18n("Command & Search Results")
            level: 4
            color: root.effectiveTextColor
            opacity: 0.85
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }

        StatusBadge {
            visible: resultsList.count > 0
            text: i18np("%1 match", "%1 matches", resultsList.count)
            accentTone: true
            monospace: true
        }
    }

    ListView {
        id: resultsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 2
        QQC2.ScrollBar.vertical: LauncherScrollBar {}
        keyNavigationEnabled: true

        model: runnerModel.count > 0 ? runnerModel.modelForRow(0) : null

        delegate: ResultCard {
            id: resultDelegate
            width: resultsList.width
            iconSource: model.decoration
            title: model.display ?? ""
            subtitle: model.subtext ?? ""
            highlighted: ListView.isCurrentItem
            badgeText: ListView.isCurrentItem ? "↵" : ""
            badgeAccent: ListView.isCurrentItem

            readonly property var itemFavId: {
                if (model.favoriteId && String(model.favoriteId).length > 0) return model.favoriteId
                if (model.url && String(model.url).length > 0) return model.url.toString()
                if (model.storageId && String(model.storageId).length > 0) return model.storageId.toString()
                return null
            }

            function run() {
                resultsList.model.trigger(index, "", null)
                if (root.closeLauncher) {
                    root.closeLauncher()
                } else {
                    root.expanded = false
                }
            }

            Keys.onReturnPressed: run()
            Keys.onMenuPressed: searchPage.openContextMenu(index, model.actionList, itemFavId)

            onClicked: resultDelegate.run()
            onRightClicked: searchPage.openContextMenu(index, model.actionList, resultDelegate.itemFavId)
        }

        Rectangle {
            visible: resultsList.count === 0
            anchors.centerIn: parent
            width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 18)
            height: emptySearchCol.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: root.cardRadius
            color: root.cardColor
            border.width: 1
            border.color: root.cardBorderColor

            Column {
                id: emptySearchCol
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "search-symbolic"
                    width: Kirigami.Units.iconSizes.large
                    height: width
                    isMask: true
                    color: root.effectiveAccent
                    opacity: 0.72
                }
                QQC2.Label {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    color: root.effectiveTextColor
                    opacity: 0.78
                    text: i18n("No results yet — try an app name, math (=42*7), or $command")
                }
            }
        }
    }

    function openContextMenu(row, actionList, favoriteId) {
        searchContextMenu.row = row
        searchContextMenu.resolvedFavoriteId = favoriteId
        const fm = rootModel.favoritesModel
        const favs = []
        if (fm && fm.enabled && favoriteId) {
            const isFav = fm.isFavorite(favoriteId)
            favs.push({
                text: isFav ? i18n("Remove from favourites") : i18n("Add to favourites"),
                icon: isFav ? "bookmark-remove" : "bookmark-new",
                actionId: isFav ? "_kicker_favorite_remove" : "_kicker_favorite_add"
            })
        }
        const base = actionList ? Array.from(actionList) : []
        const list = (base.length > 0 && favs.length > 0)
            ? favs.concat([{ type: "separator" }], base)
            : favs.concat(base)
        if (list.length === 0) {
            return
        }
        searchContextMenu.populateActions(list, a => searchPage.runAction(a))
        searchContextMenu.popup()
    }

    function runAction(a) {
        if (!a.actionId) return
        if (a.actionId.startsWith("_kicker_favorite_")) {
            const fm = rootModel.favoritesModel
            const favId = searchContextMenu.resolvedFavoriteId
            if (fm && favId) {
                if (a.actionId === "_kicker_favorite_remove") {
                    fm.removeFavorite(favId)
                } else if (a.actionId === "_kicker_favorite_add") {
                    fm.addFavorite(favId)
                }
            }
            return
        }
        if (resultsList.model && resultsList.model.trigger) {
            const close = resultsList.model.trigger(searchContextMenu.row, a.actionId, a.actionArgument)
            if (close) {
                if (root.closeLauncher) {
                    root.closeLauncher()
                } else {
                    root.expanded = false
                }
            }
        }
    }

    LauncherMenu {
        id: searchContextMenu
        property int row: -1
        property var resolvedFavoriteId: null
    }
}
