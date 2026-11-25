// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Web shortcuts: user-defined URLs from launcher settings,
// one per line as "Label | https://url" (label optional)
ColumnLayout {
    id: linksPage
    spacing: Kirigami.Units.smallSpacing

    function focusContent() {
        if (links.length > 0) {
            linksGrid.forceActiveFocus()
        }
    }

    readonly property var links: {
        const out = []
        const lines = (Plasmoid.configuration.webLinks || "").split("\n")
        for (const line of lines) {
            const t = line.trim()
            if (t.length === 0) {
                continue
            }
            const sep = t.indexOf("|")
            let label, url
            if (sep > -1) {
                label = t.slice(0, sep).trim()
                url = t.slice(sep + 1).trim()
            } else {
                url = t
                label = t.replace(/^https?:\/\//, "").replace(/\/.*$/, "")
            }
            if (!/^https?:\/\//.test(url)) {
                url = "https://" + url
            }
            const domain = url.replace(/^https?:\/\//, "").replace(/[/:].*$/, "")
            out.push({ label: label, url: url, domain: domain })
        }
        return out
    }

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading {
            text: i18n("Web links")
            level: 3
            color: root.effectiveTextColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: linksPage.links.length > 0
            text: String(linksPage.links.length)
            monospace: true
        }
        MenuButton {}
    }

    // empty state: Future glass card pointing at settings
    Item {
        visible: linksPage.links.length === 0
        Layout.fillWidth: true
        Layout.fillHeight: true

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 19)
            height: emptyLinksCol.implicitHeight + Kirigami.Units.largeSpacing * 2.2
            radius: root.cardRadius
            color: root.cardColor
            border.width: 1
            border.color: root.cardBorderColor

            Column {
                id: emptyLinksCol
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.largeSpacing * 2
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "internet-web-browser"
                    width: Kirigami.Units.iconSizes.huge
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
                    text: i18n("No links yet. Add some in launcher settings — one per line, like:\nYouTube | https://youtube.com")
                }
                QQC2.Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n("Open launcher settings")
                    icon.name: "configure"
                    onClicked: Plasmoid.internalAction("configure").trigger()
                }
            }
        }
    }

    GridView {
        id: linksGrid
        visible: linksPage.links.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        rightMargin: Kirigami.Units.smallSpacing * 1.5

        readonly property int baseIconSize: Plasmoid.configuration.iconSize
        cellWidth: Math.floor((width - rightMargin) / Math.max(1, Math.floor((width - rightMargin) / (baseIconSize + Kirigami.Units.gridUnit * 3))))
        cellHeight: baseIconSize + Kirigami.Units.gridUnit * 2

        model: linksPage.links
        currentIndex: -1

        onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0) currentIndex = 0
        Keys.onReturnPressed: if (currentItem) currentItem.clicked()
        Keys.onEscapePressed: searchField.forceActiveFocus()

        QQC2.ScrollBar.vertical: LauncherScrollBar {}

        delegate: GridTile {
            width: linksGrid.cellWidth
            height: linksGrid.cellHeight
            // favicon via DuckDuckGo's icon service; generic globe until it
            // loads (or if the machine is offline)
            icon: "internet-web-browser"
            imageSource: "https://icons.duckduckgo.com/ip3/" + modelData.domain + ".ico"
            label: modelData.label
            tooltip: modelData.url
            iconSize: linksGrid.baseIconSize
            onClicked: {
                Qt.openUrlExternally(modelData.url)
                if (root.closeLauncher) {
                    root.closeLauncher()
                } else {
                    root.expanded = false
                }
            }
        }
    }
}
