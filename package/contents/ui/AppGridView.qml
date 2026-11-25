// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Reusable icon grid for any Kicker AbstractModel: mouse + full keyboard
// driving, drag-out (pin to desktop/panel/task manager), drag-reorder on
// the favourites grid, and a context menu built from the model's action
// list (desktop-file actions, pin to task manager, edit, hide…).
GridView {
    id: grid

    property bool showLabels: Plasmoid.configuration.showLabels
    readonly property int baseIconSize: Plasmoid.configuration.iconSize
    // favourites: dragging inside the grid reorders instead of dragging out
    property bool reorderable: false
    property string emptyIcon: ""
    property string emptyText: ""

    signal triggered()

    clip: true
    rightMargin: Kirigami.Units.smallSpacing * 1.5
    cellWidth: Math.floor((width - rightMargin) / Math.max(1, Math.floor((width - rightMargin) / (baseIconSize + Kirigami.Units.gridUnit * 2))))
    cellHeight: baseIconSize + (showLabels ? Kirigami.Units.gridUnit * 1.8 : Kirigami.Units.gridUnit)
    currentIndex: -1
    keyNavigationWraps: false

    QQC2.ScrollBar.vertical: LauncherScrollBar {}

    function activate(row) {
        grid.model.trigger(row, "", null)
        grid.triggered()
        if (root.closeLauncher) {
            root.closeLauncher()
        } else {
            root.expanded = false
        }
    }

    onActiveFocusChanged: {
        if (activeFocus && currentIndex < 0 && count > 0) {
            currentIndex = 0
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (currentIndex >= 0) {
                activate(currentIndex)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            searchField.forceActiveFocus()
            event.accepted = true
        } else if (event.key === Qt.Key_Menu) {
            if (currentItem) {
                currentItem.rightClicked()
            }
            event.accepted = true
        } else if (event.text.length === 1 && event.text.charCodeAt(0) >= 0x20
                   && !(event.modifiers & ~Qt.ShiftModifier)) {
            // typing anywhere starts a search, like the stock launchers
            fullRep.typeAhead(event.text)
            event.accepted = true
        }
    }

    move: Transition {
        NumberAnimation { duration: root.animShort; properties: "x, y"; easing.type: Easing.OutQuad }
    }
    moveDisplaced: Transition {
        NumberAnimation { duration: root.animShort; properties: "x, y"; easing.type: Easing.OutQuad }
    }

    delegate: GridTile {
        width: grid.cellWidth
        height: grid.cellHeight
        icon: model.decoration
        label: model.display ?? ""
        showLabel: grid.showLabels
        tooltip: grid.showLabels ? "" : (model.display ?? "")
        iconSize: grid.baseIconSize
        draggable: true
        dragUrl: model.url ?? ""
        favoriteDrag: grid.reorderable
        itemIndex: index
        favoriteId: {
            if (model.favoriteId && String(model.favoriteId).length > 0) return model.favoriteId
            if (model.url && String(model.url).length > 0) return model.url.toString()
            if (model.storageId && String(model.storageId).length > 0) return model.storageId.toString()
            return null
        }
        onClicked: grid.activate(index)
        onRightClicked: {
            const favId = favoriteId
            grid.openContextMenu(index, model.actionList, favId)
        }
    }

    // Sleek optional empty state
    Rectangle {
        visible: grid.count === 0 && grid.emptyText.length > 0
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 17)
        height: emptyCol.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: root.cardRadius
        color: root.cardColor
        border.width: 1
        border.color: root.cardBorderColor

        Column {
            id: emptyCol
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.largeSpacing * 2
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: grid.emptyIcon.length > 0
                source: grid.emptyIcon
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
                opacity: 0.75
                text: grid.emptyText
            }
        }
    }

    // live reorder while a favourite (grid tile or carousel tile — both
    // share the favourites model) is dragged across the grid
    DropArea {
        anchors.fill: parent
        enabled: grid.reorderable
        onPositionChanged: drag => {
            const src = drag.source
            if (!src || !src.favoriteDrag || src.itemIndex === undefined || src.itemIndex < 0) {
                return
            }
            const idx = grid.indexAt(grid.contentX + drag.x, grid.contentY + drag.y)
            if (idx >= 0 && idx !== src.itemIndex && grid.model.moveRow) {
                grid.model.moveRow(src.itemIndex, idx)
            }
        }
    }

    // ---- context menu, rebuilt per item from the Kicker action list ----
    function openContextMenu(row, actionList, favoriteId) {
        appContextMenu.row = row
        appContextMenu.resolvedFavoriteId = favoriteId
        const favs = favoriteActions(favoriteId, actionList)
        const base = actionList ? Array.from(actionList) : []
        const list = base.length > 0 && favs.length > 0
            ? base.concat([{ type: "separator" }], favs)
            : base.concat(favs)
        if (list.length === 0) {
            return
        }
        appContextMenu.populateActions(list, a => grid.runAction(a))
        appContextMenu.popup()
    }

    function favoriteActions(favoriteId, actionList) {
        // If actionList already provides a favorite action, don't duplicate it
        if (actionList && actionList.length > 0) {
            for (let i = 0; i < actionList.length; i++) {
                const act = actionList[i]
                if (act && act.actionId) {
                    const idStr = String(act.actionId).toLowerCase()
                    if (idStr.indexOf("favorite") !== -1 || idStr.indexOf("favourite") !== -1) {
                        return []
                    }
                }
            }
        }
        const fm = (grid.model && grid.model.favoritesModel) ? grid.model.favoritesModel : rootModel.favoritesModel
        if (!fm || !fm.enabled || !favoriteId) {
            return []
        }
        const arg = { favoriteModel: fm, favoriteId: favoriteId }
        if (fm.isFavorite(favoriteId)) {
            return [{ text: i18n("Remove from favourites"), icon: "bookmark-remove",
                      actionId: "_kicker_favorite_remove", actionArgument: arg }]
        }
        return [{ text: i18n("Add to favourites"), icon: "bookmark-new",
                  actionId: "_kicker_favorite_add", actionArgument: arg }]
    }

    function runAction(a) {
        if (!a.actionId) {
            return
        }
        if (a.actionId.startsWith("_kicker_favorite_")) {
            const fm = (grid.model && grid.model.favoritesModel) ? grid.model.favoritesModel : rootModel.favoritesModel
            const arg = a.actionArgument
            const favId = (arg && arg.favoriteId) ? arg.favoriteId : appContextMenu.resolvedFavoriteId
            const favModel = (arg && arg.favoriteModel) ? arg.favoriteModel : fm
            if (favModel && favId) {
                if (a.actionId === "_kicker_favorite_remove") {
                    favModel.removeFavorite(favId)
                } else if (a.actionId === "_kicker_favorite_add") {
                    favModel.addFavorite(favId)
                }
                return
            }
            if (grid.model && grid.model.trigger) {
                const res = grid.model.trigger(appContextMenu.row, a.actionId, a.actionArgument)
                if (res !== undefined) return
            }
            return
        }
        const close = grid.model.trigger(appContextMenu.row, a.actionId, a.actionArgument)
        if (close) {
            if (root.closeLauncher) {
                root.closeLauncher()
            } else {
                root.expanded = false
            }
        }
    }

    LauncherMenu {
        id: appContextMenu
        property int row: -1
        property var resolvedFavoriteId: null
    }
}
