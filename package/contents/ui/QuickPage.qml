// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils

// Quick actions: one-click system chores and jump-points.
// Entries either run a command (cmd) or open a System Settings module (kcm).
ColumnLayout {
    id: quickPage
    spacing: Kirigami.Units.smallSpacing

    function focusContent() {
        quickGrid.forceActiveFocus()
    }

    readonly property var actions: [
        { icon: "system-software-update", label: i18n("Full system update"),
          cmd: root.effectiveUpdateCmd },
        { icon: "spectacle", label: i18n("Screenshot"), cmd: "spectacle" },
        { icon: "utilities-system-monitor", label: i18n("System monitor"), cmd: "plasma-systemmonitor" },
        { icon: "utilities-terminal", label: i18n("Terminal"), cmd: "konsole" },
        { icon: "system-file-manager", label: i18n("Files"), cmd: "dolphin" },
        { icon: "folder-download", label: i18n("Downloads"), cmd: "xdg-open ~/Downloads" },
        { icon: "user-trash", label: i18n("Trash"), cmd: "xdg-open trash:/" },
        { icon: "preferences-desktop-display", label: i18n("Displays"), kcm: "kcm_kscreen" },
        { icon: "audio-volume-high", label: i18n("Audio"), kcm: "kcm_pulseaudio" },
        { icon: "preferences-system-network", label: i18n("Network"), kcm: "kcm_networkmanagement" },
        { icon: "preferences-system-bluetooth", label: i18n("Bluetooth"), kcm: "kcm_bluetooth" },
        { icon: "preferences-desktop-theme-global", label: i18n("Appearance"), kcm: "kcm_lookandfeel" }
    ]

    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing
        Kirigami.Heading {
            text: i18n("Quick actions")
            level: 3
            color: root.effectiveTextColor
            Layout.leftMargin: Kirigami.Units.smallSpacing
            Layout.fillWidth: true
        }
        StatusBadge {
            visible: root.distroLabel.length > 0
            text: root.distroLabel
            accentTone: true
        }
        MenuButton {}
    }

    QQC2.Label {
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.smallSpacing
        Layout.rightMargin: Kirigami.Units.smallSpacing
        text: i18n("Update command auto-detects your distro — override in launcher settings")
        color: root.effectiveTextColor
        opacity: 0.6
        elide: Text.ElideRight
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    GridView {
        id: quickGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        rightMargin: Kirigami.Units.smallSpacing * 1.5

        readonly property int baseIconSize: Plasmoid.configuration.iconSize
        cellWidth: Math.floor((width - rightMargin) / Math.max(1, Math.floor((width - rightMargin) / (baseIconSize + Kirigami.Units.gridUnit * 3))))
        cellHeight: baseIconSize + Kirigami.Units.gridUnit * 2

        model: quickPage.actions
        currentIndex: -1

        onActiveFocusChanged: if (activeFocus && currentIndex < 0 && count > 0) currentIndex = 0
        Keys.onReturnPressed: if (currentItem) currentItem.clicked()
        Keys.onEscapePressed: searchField.forceActiveFocus()

        QQC2.ScrollBar.vertical: LauncherScrollBar {}

        delegate: GridTile {
            width: quickGrid.cellWidth
            height: quickGrid.cellHeight
            icon: modelData.icon
            label: modelData.label
            iconSize: quickGrid.baseIconSize
            onClicked: {
                if (modelData.kcm) {
                    KCMUtils.KCMLauncher.openSystemSettings(modelData.kcm)
                } else {
                    root.execCmd(modelData.cmd)
                }
                if (root.closeLauncher) {
                    root.closeLauncher()
                } else {
                    root.expanded = false
                }
            }
        }
    }
}
