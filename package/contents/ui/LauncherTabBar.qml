// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Future horizontal capsule pill tab bar with smooth auto-pan,
// wheel scrolling, overflow nudge buttons, and theme-reactive pill styling.
Item {
    id: tabBar

    // Array of { text: string, icon: string }
    property var model: []
    property int currentIndex: 0
    signal tabActivated(int index)

    implicitHeight: Math.round(Kirigami.Units.gridUnit * 1.85)
    Layout.preferredHeight: implicitHeight

    function ensureVisible(idx) {
        if (idx >= 0 && idx < tabList.count) {
            tabList.positionViewAtIndex(idx, ListView.Contain)
        }
    }

    onCurrentIndexChanged: ensureVisible(currentIndex)

    readonly property bool overflowsLeft: tabList.contentWidth > tabList.width && tabList.contentX > 2
    readonly property bool overflowsRight: tabList.contentWidth > tabList.width
        && (tabList.contentX + tabList.width) < (tabList.contentWidth - 2)

    function scrollBy(delta) {
        const maxX = Math.max(0, tabList.contentWidth - tabList.width)
        tabList.contentX = Math.max(0, Math.min(maxX, tabList.contentX + delta))
    }

    RowLayout {
        anchors.fill: parent
        spacing: Math.max(2, Math.round(Kirigami.Units.smallSpacing * 0.5))

        // Left overflow scroll nudge
        Rectangle {
            visible: tabBar.overflowsLeft
            Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 1.15)
            Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.55)
            Layout.alignment: Qt.AlignVCenter
            radius: root.pillRadius
            color: leftArrowMouse.containsMouse ? root.effectiveTileHoverColor : root.cardColor
            border.width: 1
            border.color: leftArrowMouse.containsMouse ? root.cardHoverBorderColor : root.cardBorderColor

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.small * 0.72
                height: width
                source: "go-previous-symbolic"
                isMask: true
                color: leftArrowMouse.containsMouse ? root.effectiveAccent : root.effectiveTextColor
            }
            MouseArea {
                id: leftArrowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tabBar.scrollBy(-Kirigami.Units.gridUnit * 6)
            }
        }

        ListView {
            id: tabList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            orientation: ListView.Horizontal
            spacing: Kirigami.Units.smallSpacing
            model: tabBar.model
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentWidth > width

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    if (tabList.contentWidth <= tabList.width) {
                        return
                    }
                    const delta = Math.abs(event.angleDelta.x) > Math.abs(event.angleDelta.y)
                        ? event.angleDelta.x
                        : event.angleDelta.y
                    tabBar.scrollBy(-delta * 0.7)
                }
            }

            delegate: Item {
                id: tabPill
                required property var modelData
                required property int index

                readonly property bool active: tabBar.currentIndex === index
                readonly property bool hovered: pillMouse.containsMouse

                height: tabList.height
                width: pillRow.implicitWidth + Kirigami.Units.smallSpacing * 3.0

                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text ?? ""

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    radius: root.pillRadius

                    color: {
                        if (tabPill.active) {
                            return root.withAlpha(
                                root.effectiveAccent,
                                root.isDark ? (root.isHud ? 0.24 : 0.20) : 0.15
                            )
                        }
                        if (tabPill.hovered) {
                            return root.withAlpha(root.effectiveTextColor, root.isDark ? 0.10 : 0.06)
                        }
                        return root.isClassic
                            ? "transparent"
                            : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.045 : 0.03)
                    }

                    border.width: 1
                    border.color: {
                        if (tabPill.active) {
                            return root.withAlpha(
                                root.effectiveAccent,
                                root.isCyber ? 0.78 : (root.isHud ? 0.65 : 0.50)
                            )
                        }
                        if (tabPill.hovered) {
                            return root.withAlpha(root.effectiveTextColor, root.isDark ? 0.18 : 0.12)
                        }
                        return root.isClassic
                            ? "transparent"
                            : root.withAlpha(root.effectiveTextColor, root.isDark ? 0.08 : 0.06)
                    }

                    Behavior on color { ColorAnimation { duration: root.animShort } }
                    Behavior on border.color { ColorAnimation { duration: root.animShort } }

                    // Subtle top specular highlight on the active pill
                    Rectangle {
                        visible: tabPill.active && !root.isClassic
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 1
                        anchors.leftMargin: Math.min(parent.radius, 12)
                        anchors.rightMargin: Math.min(parent.radius, 12)
                        height: 1
                        color: root.specularColor
                        opacity: 0.7
                    }
                }

                RowLayout {
                    id: pillRow
                    anchors.centerIn: parent
                    spacing: Math.max(4, Math.round(Kirigami.Units.smallSpacing * 0.8))

                    Kirigami.Icon {
                        visible: (tabPill.modelData.icon ?? "").length > 0
                        source: tabPill.modelData.icon ?? ""
                        Layout.preferredWidth: Kirigami.Units.iconSizes.small * 0.85
                        Layout.preferredHeight: Layout.preferredWidth
                        isMask: true
                        color: tabPill.active ? root.effectiveAccent : root.effectiveTextColor
                        opacity: tabPill.active ? 1.0 : (tabPill.hovered ? 0.92 : 0.68)
                        Behavior on color { ColorAnimation { duration: root.animShort } }
                        Behavior on opacity { NumberAnimation { duration: root.animShort } }
                    }

                    QQC2.Label {
                        text: tabPill.modelData.text ?? ""
                        color: root.effectiveTextColor
                        opacity: tabPill.active ? 1.0 : (tabPill.hovered ? 0.92 : 0.72)
                        font.weight: tabPill.active ? Font.DemiBold : Font.Normal
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        Behavior on opacity { NumberAnimation { duration: root.animShort } }
                    }
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tabBar.currentIndex = tabPill.index
                        tabBar.tabActivated(tabPill.index)
                    }
                }
            }
        }

        // Right overflow scroll nudge
        Rectangle {
            visible: tabBar.overflowsRight
            Layout.preferredWidth: Math.round(Kirigami.Units.gridUnit * 1.15)
            Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.55)
            Layout.alignment: Qt.AlignVCenter
            radius: root.pillRadius
            color: rightArrowMouse.containsMouse ? root.effectiveTileHoverColor : root.cardColor
            border.width: 1
            border.color: rightArrowMouse.containsMouse ? root.cardHoverBorderColor : root.cardBorderColor

            Kirigami.Icon {
                anchors.centerIn: parent
                width: Kirigami.Units.iconSizes.small * 0.72
                height: width
                source: "go-next-symbolic"
                isMask: true
                color: rightArrowMouse.containsMouse ? root.effectiveAccent : root.effectiveTextColor
            }
            MouseArea {
                id: rightArrowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tabBar.scrollBy(Kirigami.Units.gridUnit * 6)
            }
        }
    }
}
