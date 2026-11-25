// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: navBtn

    property string iconName
    property string label
    property bool active: false
    signal clicked()

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredWidth: parent.width - Kirigami.Units.smallSpacing * 2
    Layout.preferredHeight: Layout.preferredWidth

    Accessible.role: Accessible.Button
    Accessible.name: navBtn.label
    Accessible.onPressAction: navBtn.clicked()
    activeFocusOnTab: true
    Keys.onReturnPressed: navBtn.clicked()
    Keys.onSpacePressed: navBtn.clicked()

    readonly property bool isSolidAccentRibbon: fullRep.ribbonStyle === 2

    // Ambient active halo behind button in Spatial & HUD themes
    Rectangle {
        visible: navBtn.active && !navBtn.isSolidAccentRibbon && (root.isSpatial || root.isHud)
        anchors.centerIn: parent
        width: parent.width * 1.05
        height: width
        radius: root.isCyber ? root.cardRadius : width / 2
        color: root.withAlpha(fullRep.accent, root.isHud ? 0.16 : 0.11)
        opacity: navBtn.active ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: root.animFast } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.isCyber ? Math.max(4, Math.round(root.cardRadius * 0.85)) : Math.round(height * 0.34)
        color: {
            if (navBtn.active) {
                if (navBtn.isSolidAccentRibbon) {
                    return Kirigami.Theme.backgroundColor
                }
                return root.withAlpha(fullRep.accent, fullRep.isDark ? (root.isHud ? 0.26 : 0.22) : 0.15)
            }
            if (mouse.containsMouse) {
                if (navBtn.isSolidAccentRibbon) {
                    return root.withAlpha(fullRep.onAccent, 0.22)
                }
                return root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.095 : 0.06)
            }
            return "transparent"
        }
        border.color: {
            if (navBtn.active && !navBtn.isSolidAccentRibbon) {
                return root.withAlpha(fullRep.accent, root.isCyber ? 0.78 : (fullRep.isDark ? 0.52 : 0.36))
            }
            if (mouse.containsMouse && !navBtn.isSolidAccentRibbon) {
                return root.withAlpha(fullRep.textColor, 0.16)
            }
            return "transparent"
        }
        border.width: 1
        Behavior on color { ColorAnimation { duration: root.animShort } }
        Behavior on border.color { ColorAnimation { duration: root.animShort } }

        // Top specular rim inside active Spatial / HUD nav pill
        Rectangle {
            visible: navBtn.active && !navBtn.isSolidAccentRibbon && !root.isClassic
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: Math.min(parent.radius, 10)
            anchors.rightMargin: Math.min(parent.radius, 10)
            height: 1
            color: root.specularColor
            opacity: 0.7
        }

        // Sleek active vertical indicator pill on the left edge with smooth expansion
        Rectangle {
            id: activeBar
            visible: !navBtn.isSolidAccentRibbon
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: root.isCyber ? 2.5 : 3
            height: navBtn.active ? Math.round(parent.height * 0.48) : 0
            radius: root.isCyber ? 1 : 1.5
            color: fullRep.accent
            opacity: navBtn.active ? 1.0 : 0.0
            Behavior on height { NumberAnimation { duration: root.animFast; easing.type: root.animEasingType; easing.overshoot: root.animOvershoot } }
            Behavior on opacity { NumberAnimation { duration: root.animFast; easing.type: Easing.OutQuad } }
        }
    }

    Kirigami.Icon {
        anchors.centerIn: parent
        width: parent.width * 0.54
        height: width
        source: navBtn.iconName
        // isMask forces a flat monochrome tint so every icon gets the full contrast colour
        isMask: true
        color: {
            if (navBtn.active) {
                return fullRep.accent
            }
            if (navBtn.isSolidAccentRibbon) {
                return fullRep.onAccent
            }
            return fullRep.textColor
        }
        opacity: navBtn.active ? 1.0 : (mouse.containsMouse ? 1.0 : 0.72)
        scale: mouse.pressed ? 0.88 : ((mouse.containsMouse && root.animEffect !== 1) ? 1.06 : 1.0)
        Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: root.animEasingType; easing.overshoot: root.animOvershoot } }
        Behavior on opacity { NumberAnimation { duration: root.animFast; easing.type: Easing.OutQuad } }
        Behavior on color { ColorAnimation { duration: root.animFast } }
    }

    QQC2.ToolTip.text: navBtn.label
    QQC2.ToolTip.visible: mouse.containsMouse
    QQC2.ToolTip.delay: 400

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: navBtn.clicked()
    }
}
