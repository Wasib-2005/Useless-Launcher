// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
import Qt.labs.platform as Platform

// Documents: two Future capsule tabs — recent files and bookmarked folders
ColumnLayout {
    id: docsPage
    spacing: Kirigami.Units.smallSpacing

    property int currentTab: 0

    function focusContent() {
        if (currentTab === 0) {
            recentList.forceActiveFocus()
        } else {
            placesList.forceActiveFocus()
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        LauncherTabBar {
            id: docsTabs
            Layout.fillWidth: true
            model: [
                { text: i18n("Recent files"), icon: "document-open-recent-symbolic" },
                { text: i18n("Folders"), icon: "folder-bookmark-symbolic" }
            ]
            currentIndex: docsPage.currentTab
            onTabActivated: idx => docsPage.currentTab = idx
        }
        MenuButton {}
    }

    Item {
        id: docsHost
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        property int shownTab: docsPage.currentTab
        property int outgoingTab: -1
        property real tabDir: 1.0
        property real progress: 1.0

        Connections {
            target: docsPage
            function onCurrentTabChanged() {
                const next = docsPage.currentTab
                if (next === docsHost.shownTab) return
                docsTabAnim.stop()
                docsHost.tabDir = next >= docsHost.shownTab ? 1.0 : -1.0
                docsHost.outgoingTab = docsHost.shownTab
                docsHost.shownTab = next
                if (root.animationsEnabled && fullRep.openProgress >= 0.99) {
                    docsHost.progress = 0.0
                    docsTabAnim.restart()
                } else {
                    docsHost.outgoingTab = -1
                    docsHost.progress = 1.0
                }
            }
        }

        NumberAnimation {
            id: docsTabAnim
            target: docsHost
            property: "progress"
            from: 0.0
            to: 1.0
            duration: root.animDuration
            easing.type: root.animEasingType
            easing.overshoot: root.animOvershoot
            onFinished: docsHost.outgoingTab = -1
        }

        function tabVisible(idx) { return shownTab === idx || (docsTabAnim.running && outgoingTab === idx) }
        function tabOpacity(idx) {
            if (!docsTabAnim.running) return shownTab === idx ? 1.0 : 0.0
            if (shownTab === idx) return Math.min(1.0, progress * 1.2)
            if (outgoingTab === idx) return Math.max(0.0, 1.0 - progress * 1.45)
            return 0.0
        }
        function tabTx(idx) {
            if (!docsTabAnim.running) return 0.0
            const eff = root.animEffect
            if (eff === 1 || eff === 2) return 0.0
            const dist = eff === 4 ? (Kirigami.Units.gridUnit * 4.8) : (Kirigami.Units.gridUnit * 3.5)
            if (shownTab === idx) return tabDir * dist * (1.0 - progress)
            if (outgoingTab === idx) return -tabDir * dist * 0.65 * progress
            return 0.0
        }
        function tabScale(idx) {
            if (!docsTabAnim.running) return 1.0
            const eff = root.animEffect
            if (eff === 1) return 1.0
            if (eff === 2) {
                if (shownTab === idx) return 0.88 + 0.12 * progress
                if (outgoingTab === idx) return 1.0 + 0.04 * progress
            }
            if (shownTab === idx) return 0.95 + 0.05 * progress
            if (outgoingTab === idx) return 1.0 - 0.03 * progress
            return 1.0
        }

        // recent documents via Kicker
        Item {
            anchors.fill: parent
            visible: docsHost.tabVisible(0)
            opacity: docsHost.tabOpacity(0)
            scale: docsHost.tabScale(0)
            transform: Translate { x: docsHost.tabTx(0) }

            ListView {
                id: recentList
                anchors.fill: parent
                clip: true
                spacing: 2
                currentIndex: -1
                keyNavigationEnabled: true
                onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0) currentIndex = 0
                Keys.onReturnPressed: if (currentItem) currentItem.clicked()
                Keys.onEscapePressed: searchField.forceActiveFocus()
                QQC2.ScrollBar.vertical: LauncherScrollBar {}

                model: Kicker.RecentUsageModel {
                    favoritesModel: rootModel.favoritesModel
                    shownItems: Kicker.RecentUsageModel.OnlyDocs
                }

                delegate: ResultCard {
                    width: recentList.width
                    iconSource: model.decoration
                    title: model.display ?? ""
                    subtitle: model.url ? String(model.url).replace("file://", "") : ""
                    highlighted: ListView.isCurrentItem && recentList.activeFocus
                    onClicked: {
                        recentList.model.trigger(index, "", null)
                        if (root.closeLauncher) {
                            root.closeLauncher()
                        } else {
                            root.expanded = false
                        }
                    }
                }
            }

            Rectangle {
                visible: recentList.count === 0
                anchors.centerIn: parent
                width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 17)
                height: docsEmptyCol.implicitHeight + Kirigami.Units.largeSpacing * 2
                radius: root.cardRadius
                color: root.cardColor
                border.width: 1
                border.color: root.cardBorderColor

                Column {
                    id: docsEmptyCol
                    anchors.centerIn: parent
                    width: parent.width - Kirigami.Units.largeSpacing * 2
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        source: "document-open-recent-symbolic"
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
                        text: i18n("No recent documents recorded yet")
                    }
                }
            }
        }

        // bookmarked folders (xdg standard places)
        Item {
            anchors.fill: parent
            visible: docsHost.tabVisible(1)
            opacity: docsHost.tabOpacity(1)
            scale: docsHost.tabScale(1)
            transform: Translate { x: docsHost.tabTx(1) }

            ListView {
                id: placesList
                anchors.fill: parent
                clip: true
                spacing: 2
                currentIndex: -1
                keyNavigationEnabled: true
                onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0) currentIndex = 0
                Keys.onReturnPressed: if (currentItem) currentItem.clicked()
                Keys.onEscapePressed: searchField.forceActiveFocus()
                QQC2.ScrollBar.vertical: LauncherScrollBar {}

                // built as a JS array with literal i18n() calls so the labels
                // actually land in the message catalog — i18n(model.name) on a
                // ListElement string can't be extracted and never translates
                model: [
                    { name: i18n("Home"), iconName: "user-home-symbolic", path: "" },
                    { name: i18n("Documents"), iconName: "folder-documents-symbolic", path: "Documents" },
                    { name: i18n("Downloads"), iconName: "folder-download-symbolic", path: "Downloads" },
                    { name: i18n("Pictures"), iconName: "folder-pictures-symbolic", path: "Pictures" },
                    { name: i18n("Videos"), iconName: "folder-videos-symbolic", path: "Videos" },
                    { name: i18n("Music"), iconName: "folder-music-symbolic", path: "Music" }
                ]

                delegate: ResultCard {
                    width: placesList.width
                    iconSource: modelData.iconName
                    title: modelData.name
                    subtitle: modelData.path === "" ? "~" : ("~/" + modelData.path)
                    highlighted: ListView.isCurrentItem && placesList.activeFocus
                    onClicked: {
                        const home = Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation)
                        Qt.openUrlExternally(modelData.path === "" ? home : home + "/" + modelData.path)
                        if (root.closeLauncher) {
                            root.closeLauncher()
                        } else {
                            root.expanded = false
                        }
                    }
                }
            }
        }
    }
}
