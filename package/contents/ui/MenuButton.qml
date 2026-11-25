// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami

// Shared launcher menu button styled to match Future capsule/tech chrome.
// Dropped into the top row of every page so the control stays in-layout.
Item {
    id: menuButton

    implicitWidth: Math.round(Kirigami.Units.gridUnit * 1.85)
    implicitHeight: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    Accessible.role: Accessible.Button
    Accessible.name: i18n("Menu")
    Accessible.onPressAction: menu.popup()

    Rectangle {
        anchors.fill: parent
        radius: root.isCyber ? root.cardRadius : width / 2
        color: btnMouse.containsMouse || menu.visible
            ? root.effectiveTileHoverColor
            : root.cardColor
        border.width: 1
        border.color: btnMouse.containsMouse || menu.visible
            ? root.cardHoverBorderColor
            : root.cardBorderColor
        Behavior on color { ColorAnimation { duration: root.animShort } }
        Behavior on border.color { ColorAnimation { duration: root.animShort } }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.small
        height: width
        source: "application-menu-symbolic"
        isMask: true
        color: btnMouse.containsMouse || menu.visible ? root.effectiveAccent : root.effectiveTextColor
        opacity: btnMouse.containsMouse || menu.visible ? 1.0 : 0.78
        scale: btnMouse.pressed ? 0.88 : (btnMouse.containsMouse && root.animEffect !== 1 ? 1.06 : 1.0)
        Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: root.animEasingType } }
        Behavior on color { ColorAnimation { duration: root.animShort } }
    }

    QQC2.ToolTip.text: i18n("Menu")
    QQC2.ToolTip.visible: btnMouse.containsMouse
    QQC2.ToolTip.delay: 400

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.popup()
    }

    LauncherMenu {
        id: menu
        LauncherMenuItem {
            checkable: true
            checked: Plasmoid.configuration.showLabels
            text: i18n("Show app names")
            onTriggered: Plasmoid.configuration.showLabels = checked
        }
        LauncherMenuItem {
            checkable: true
            checked: Plasmoid.configuration.showHudBar
            text: i18n("Show HUD status bar")
            onTriggered: Plasmoid.configuration.showHudBar = checked
        }
        QQC2.MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: root.withAlpha(root.effectiveTextColor, root.isDark ? 0.14 : 0.10)
            }
        }
        LauncherMenuItem {
            text: i18n("Launcher settings…")
            icon.name: "configure"
            onTriggered: Plasmoid.internalAction("configure").trigger()
        }
    }
}
