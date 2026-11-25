// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Shared Future list card used by SearchPage, DocsPage, and PlacesPage.
// Supports an icon well, subtitle, optional trailing badge, optional usage bar,
// left luminous selection indicator, and right-click context trigger.
Item {
    id: card

    property var iconSource: ""
    property string title: ""
    property string subtitle: ""
    property string badgeText: ""
    property bool badgeAccent: false
    property bool highlighted: false
    property real progress: -1.0   // -1 hides the progress bar; 0..1 renders storage usage
    property bool showChevron: true
    property string tooltip: ""

    signal clicked()
    signal rightClicked()

    readonly property bool activeState: card.highlighted || cardMouse.containsMouse
    implicitHeight: card.progress >= 0
        ? Math.round(Kirigami.Units.gridUnit * 3.15)
        : (card.subtitle.length > 0
            ? Math.round(Kirigami.Units.gridUnit * 2.85)
            : Math.round(Kirigami.Units.gridUnit * 2.45))

    Accessible.role: Accessible.Button
    Accessible.name: card.title

    Rectangle {
        id: cardBg
        anchors.fill: parent
        anchors.topMargin: 2
        anchors.bottomMargin: 2
        radius: root.cardRadius

        color: card.activeState ? root.effectiveTileHoverColor : root.cardColor
        border.width: 1
        border.color: card.activeState ? root.cardHoverBorderColor : root.cardBorderColor

        Behavior on color { ColorAnimation { duration: root.animShort } }
        Behavior on border.color { ColorAnimation { duration: root.animShort } }

        // Specular top sheen when active
        Rectangle {
            visible: card.activeState && !root.isClassic
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: parent.radius
            anchors.rightMargin: parent.radius
            height: 1
            color: root.specularColor
            opacity: 0.6
        }

        // Luminous left active bar
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 3
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: card.activeState ? Math.round(parent.height * 0.48) : 0
            radius: 1.5
            color: root.effectiveAccent
            opacity: card.activeState ? 1.0 : 0.0
            Behavior on height { NumberAnimation { duration: root.animFast; easing.type: root.animEasingType } }
            Behavior on opacity { NumberAnimation { duration: root.animFast } }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2.2
        anchors.rightMargin: Kirigami.Units.smallSpacing * 1.8
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.smallSpacing * 1.4

            // Framed icon well
            Rectangle {
                Layout.preferredWidth: Math.round(Kirigami.Units.iconSizes.smallMedium * 1.38)
                Layout.preferredHeight: Layout.preferredWidth
                radius: Math.max(4, Math.round(root.cardRadius * 0.72))
                color: card.activeState
                    ? root.withAlpha(root.effectiveAccent, root.isDark ? 0.16 : 0.11)
                    : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.06 : 0.04)
                border.width: 1
                border.color: card.activeState
                    ? root.withAlpha(root.effectiveAccent, 0.32)
                    : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.09 : 0.06)
                Behavior on color { ColorAnimation { duration: root.animShort } }
                Behavior on border.color { ColorAnimation { duration: root.animShort } }

                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.smallMedium
                    height: width
                    source: card.iconSource
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                QQC2.Label {
                    Layout.fillWidth: true
                    text: card.title
                    color: root.effectiveTextColor
                    font.weight: card.activeState ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    visible: card.subtitle.length > 0
                    text: card.subtitle
                    color: root.effectiveTextColor
                    opacity: 0.62
                    elide: Text.ElideRight
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            StatusBadge {
                visible: card.badgeText.length > 0
                text: card.badgeText
                accentTone: card.badgeAccent || card.activeState
                monospace: true
            }

            Kirigami.Icon {
                visible: card.showChevron && card.activeState
                source: "go-next-symbolic"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small * 0.85
                Layout.preferredHeight: Layout.preferredWidth
                isMask: true
                color: root.effectiveAccent
                opacity: card.activeState ? 0.9 : 0.0
                Behavior on opacity { NumberAnimation { duration: root.animShort } }
            }
        }

        // Optional mounted-drive usage bar
        Rectangle {
            visible: card.progress >= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            radius: 1.5
            color: root.withAlpha(root.effectiveTextColor, root.isDark ? 0.10 : 0.08)

            Rectangle {
                height: parent.height
                width: Math.max(4, parent.width * Math.max(0, Math.min(1, card.progress)))
                radius: parent.radius
                color: card.progress > 0.85
                    ? Qt.color("#fb7185")
                    : root.effectiveAccent
                Behavior on width { NumberAnimation { duration: root.animFast; easing.type: Easing.OutCubic } }
            }
        }
    }

    QQC2.ToolTip.text: card.tooltip
    QQC2.ToolTip.visible: card.tooltip.length > 0 && cardMouse.containsMouse
    QQC2.ToolTip.delay: 600

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                card.rightClicked()
            } else {
                card.clicked()
            }
        }
    }
}
