// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// All Apps: Future category pill tabs across the top + icon grid
ColumnLayout {
    id: appsPage
    spacing: Kirigami.Units.smallSpacing

    property int currentCategory: 0

    function focusContent() {
        appGrid.forceActiveFocus()
    }

    // the "All Applications" row showAllApps adds — pinned as first tab
    // (icon name per kicker's rootmodel.cpp AllAppsGroupEntry)
    readonly property int allAppsRow: {
        for (let i = 0; i < rootModel.count; i++) {
            const icon = String(rootModel.data(rootModel.index(i, 0), Qt.DecorationRole) || "")
            if (icon === "applications-all-symbolic" || icon === "applications-all") {
                return i
            }
        }
        return -1
    }

    // conventional menu order (everyday categories first, System near the
    // end after Utilities, Help dead last) instead of plain alphabetical.
    // Primary match is the category's icon name — those come from the XDG
    // menu definition and never get translated, so ordering survives any
    // system language. The display-name heuristic is only a fallback.
    readonly property var iconRank: ({
        "applications-internet": 10,
        "applications-multimedia": 20,
        "applications-graphics": 30,
        "applications-office": 40,
        "applications-games": 50,
        "applications-education": 60,
        "applications-science": 70,
        "applications-development": 80,
        "applications-utilities": 90,
        "applications-other": 95,
        "preferences-desktop": 100,
        "applications-system": 110,
        "applications-engineering": 75,
        "help-browser": 1000
    })
    function categoryRank(row) {
        const icon = String(rootModel.data(rootModel.index(row, 0), Qt.DecorationRole) || "")
        if (icon in iconRank) {
            return iconRank[icon]
        }
        const n = String(rootModel.data(rootModel.index(row, 0), Qt.DisplayRole) || "").toLowerCase()
        const buckets = [
            ["internet", "network"],
            ["multimedia", "sound", "video", "audio"],
            ["graphics", "photo"],
            ["office"],
            ["game"],
            ["education"],
            ["science", "math"],
            ["development", "programming"],
            ["utilities", "accessories", "tool"],
        ]
        for (let i = 0; i < buckets.length; i++) {
            if (buckets[i].some(k => n.includes(k))) {
                return (i + 1) * 10
            }
        }
        if (n.includes("help")) return 1000
        if (n.includes("lost")) return 990
        if (n.includes("settings") || n.includes("administration")) return 100
        if (n.includes("system")) return 110
        return 95  // anything unrecognized: after utilities, before settings
    }

    // visible categories, empty ones dropped, in usability order
    // (re-evaluates whenever the app model repopulates via rootModel.count)
    readonly property var categoryRows: {
        const rows = []
        for (let i = 0; i < rootModel.count; i++) {
            if (i === allAppsRow) {
                continue
            }
            const m = rootModel.modelForRow(i)
            if (!m || m.count < 1) {
                continue
            }
            rows.push(i)
        }
        const name = r => rootModel.data(rootModel.index(r, 0), Qt.DisplayRole) || ""
        rows.sort((a, b) => categoryRank(a) - categoryRank(b)
                            || name(a).localeCompare(name(b)))
        return allAppsRow >= 0 ? [allAppsRow].concat(rows) : rows
    }
    onCategoryRowsChanged: currentCategory = Math.min(currentCategory, Math.max(0, categoryRows.length - 1))

    readonly property var categoryTabsModel: {
        const out = []
        for (let i = 0; i < categoryRows.length; i++) {
            const idx = rootModel.index(categoryRows[i], 0)
            out.push({
                text: String(rootModel.data(idx, Qt.DisplayRole) ?? ""),
                icon: String(rootModel.data(idx, Qt.DecorationRole) ?? "")
            })
        }
        return out
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        LauncherTabBar {
            id: categoryTabs
            Layout.fillWidth: true
            model: appsPage.categoryTabsModel
            currentIndex: appsPage.currentCategory
            onTabActivated: idx => appsPage.currentCategory = idx
        }

        StatusBadge {
            visible: appGrid.count > 0
            text: String(appGrid.count)
            monospace: true
        }

        MenuButton {}
    }

    Item {
        id: appGridHost
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        property int lastCategory: 0
        property real catDir: 1.0
        property real catProgress: 1.0

        Connections {
            target: appsPage
            function onCurrentCategoryChanged() {
                appGridHost.catDir = appsPage.currentCategory >= appGridHost.lastCategory ? 1.0 : -1.0
                appGridHost.lastCategory = appsPage.currentCategory
                if (root.animationsEnabled && fullRep.openProgress >= 0.99) {
                    categoryTransitionAnim.stop()
                    appGridHost.catProgress = 0.0
                    categoryTransitionAnim.restart()
                } else {
                    appGridHost.catProgress = 1.0
                }
            }
        }

        NumberAnimation {
            id: categoryTransitionAnim
            target: appGridHost
            property: "catProgress"
            from: 0.0
            to: 1.0
            duration: root.animDuration
            easing.type: root.animEasingType
            easing.overshoot: root.animOvershoot
        }

        AppGridView {
            id: appGrid
            anchors.fill: parent
            model: appsPage.categoryRows.length > 0
                ? rootModel.modelForRow(appsPage.categoryRows[
                      Math.min(appsPage.currentCategory, appsPage.categoryRows.length - 1)])
                : null

            readonly property real p: appGridHost.catProgress
            readonly property int eff: root.animEffect
            opacity: eff === 1 ? p : Math.min(1.0, p * 1.2)
            scale: eff === 2 ? (0.88 + 0.12 * p) : (eff === 1 ? 1.0 : (0.95 + 0.05 * p))
            transform: Translate {
                x: {
                    if (appGrid.eff === 1 || appGrid.eff === 2) return 0.0
                    const dist = appGrid.eff === 4 ? (Kirigami.Units.gridUnit * 4.8) : (Kirigami.Units.gridUnit * 3.5)
                    return appGridHost.catDir * dist * (1.0 - appGrid.p)
                }
            }
        }
    }
}
