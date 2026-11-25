// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support
import Qt.labs.platform as Platform

// Places: standard user folders + mounted drives with live capacity bars
ColumnLayout {
    id: placesPage
    spacing: Kirigami.Units.smallSpacing

    readonly property string home: Platform.StandardPaths.writableLocation(Platform.StandardPaths.HomeLocation).toString().replace("file://", "")

    function focusContent() {
        const first = foldersRepeater.itemAt(0)
        if (first) {
            first.forceActiveFocus()   // Tab/Shift+Tab walk the rest
        }
    }

    readonly property var folders: [
        { label: i18n("Home"), icon: "user-home-symbolic", path: home, sub: "~" },
        { label: i18n("Documents"), icon: "folder-documents-symbolic", path: home + "/Documents", sub: "~/Documents" },
        { label: i18n("Downloads"), icon: "folder-download-symbolic", path: home + "/Downloads", sub: "~/Downloads" },
        { label: i18n("Pictures"), icon: "folder-pictures-symbolic", path: home + "/Pictures", sub: "~/Pictures" },
        { label: i18n("Videos"), icon: "folder-videos-symbolic", path: home + "/Videos", sub: "~/Videos" },
        { label: i18n("Music"), icon: "folder-music-symbolic", path: home + "/Music", sub: "~/Music" },
        { label: i18n("Root (/)"), icon: "drive-harddisk-root-symbolic", path: "/", sub: "/" },
        { label: i18n("Network"), icon: "folder-network-symbolic", path: "remote:/", sub: "remote:/" }
    ]

    // mounted drives, refreshed each time the page is shown
    property var drives: []

    P5Support.DataSource {
        id: driveProbe
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            placesPage.parseDrives(data.stdout || "")
        }
    }

    function refreshDrives() {
        driveProbe.connectSource("lsblk -J -o NAME,LABEL,MOUNTPOINT,SIZE,FSUSED,FSUSE%,TYPE,RM 2>/dev/null")
    }

    function parseDrives(stdout) {
        const found = []
        const skip = mp => !mp || mp === "[SWAP]" || mp.startsWith("/boot")
        function walk(devs) {
            if (!devs) return
            for (const d of devs) {
                if (!skip(d.mountpoint)) {
                    const pctRaw = d["fsuse%"] ? String(d["fsuse%"]).replace("%", "") : ""
                    const pctNum = pctRaw.length > 0 ? Number(pctRaw) : NaN
                    const pct = !isNaN(pctNum) ? Math.max(0, Math.min(1, pctNum / 100)) : -1
                    const used = d.fsused ? String(d.fsused) : ""
                    const badge = used.length > 0 && d.size ? (used + " / " + d.size) : (d.size || "")
                    found.push({
                        label: d.label && d.label.length > 0 ? d.label
                             : (d.mountpoint === "/" ? i18n("System")
                                : d.mountpoint.split("/").pop()),
                        icon: d.rm ? "drive-removable-media-symbolic" : "drive-harddisk-symbolic",
                        path: d.mountpoint,
                        detail: d.size || "",
                        badge: badge,
                        progress: pct
                    })
                }
                walk(d.children)
            }
        }
        try {
            walk(JSON.parse(stdout).blockdevices)
        } catch (e) { /* lsblk missing or odd output — just show folders */ }
        drives = found
    }

    onVisibleChanged: if (visible) refreshDrives()
    Component.onCompleted: refreshDrives()

    RowLayout {
        Layout.fillWidth: true
        Kirigami.Heading {
            text: i18n("Places")
            level: 3
            color: root.effectiveTextColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: placesPage.drives.length > 0
            text: i18np("%1 drive", "%1 drives", placesPage.drives.length)
            monospace: true
        }
        MenuButton {}
    }

    QQC2.ScrollView {
        id: placesScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        QQC2.ScrollBar.vertical: LauncherScrollBar {}
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            width: placesScroll.availableWidth
            spacing: 2

            Repeater {
                id: foldersRepeater
                model: placesPage.folders
                ResultCard {
                    Layout.fillWidth: true
                    iconSource: modelData.icon
                    title: modelData.label
                    subtitle: modelData.sub
                    activeFocusOnTab: true
                    Keys.onReturnPressed: clicked()
                    Keys.onEscapePressed: searchField.forceActiveFocus()
                    onClicked: {
                        Qt.openUrlExternally(modelData.path.startsWith("remote:")
                            ? modelData.path : "file://" + modelData.path)
                        if (root.closeLauncher) {
                            root.closeLauncher()
                        } else {
                            root.expanded = false
                        }
                    }
                }
            }

            RowLayout {
                visible: placesPage.drives.length > 0
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing * 2
                Layout.bottomMargin: Kirigami.Units.smallSpacing / 2
                Layout.leftMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Heading {
                    text: i18n("Drives")
                    level: 4
                    color: root.effectiveTextColor
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: root.withAlpha(root.effectiveTextColor, root.isDark ? 0.12 : 0.09)
                }
            }

            Repeater {
                model: placesPage.drives
                ResultCard {
                    Layout.fillWidth: true
                    iconSource: modelData.icon
                    title: modelData.label
                    subtitle: modelData.path
                    badgeText: modelData.badge
                    progress: modelData.progress
                    tooltip: i18n("%1 — %2", modelData.path, modelData.detail)
                    activeFocusOnTab: true
                    Keys.onReturnPressed: clicked()
                    Keys.onEscapePressed: searchField.forceActiveFocus()
                    onClicked: {
                        Qt.openUrlExternally("file://" + modelData.path)
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
