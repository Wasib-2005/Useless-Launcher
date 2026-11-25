// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// Shared grid tile: Future glass/tech squircle card, luminous icon halo,
// specular rim, expanding pulse ring on click, optional label, tooltip.
Item {
    id: tile

    property var icon
    property string label: ""
    property bool showLabel: true
    property url imageSource: ""
    property string tooltip: ""
    property int iconSize: Kirigami.Units.iconSizes.medium
    // drag-and-drop: apps drag out as URLs (pin to desktop/panel/task
    // manager); favoriteDrag marks drags the favourites grid reorders
    property bool draggable: false
    property url dragUrl
    property bool favoriteDrag: false
    // exposed for DropAreas reading drag.source (reorder / add-favourite)
    property int itemIndex: -1
    property var favoriteId: null
    readonly property bool dragActive: dragHandler.active

    signal clicked()
    signal rightClicked()

    readonly property bool imageReady: imageSource.toString().length > 0
        && img.status === Image.Ready
    readonly property bool keyFocused: GridView.isCurrentItem
        && (GridView.view ? GridView.view.activeFocus : false)
    readonly property bool activeState: tileMouse.containsMouse || tile.keyFocused

    Accessible.role: Accessible.Button
    Accessible.name: label

    Drag.dragType: Drag.Automatic
    Drag.mimeData: tile.favoriteDrag
        ? { "favoritedrag": "", "text/uri-list": [tile.dragUrl] }
        : { "text/uri-list": [tile.dragUrl] }

    DragHandler {
        id: dragHandler
        enabled: tile.draggable && tile.dragUrl.toString().length > 0
        target: null
        onActiveChanged: {
            if (active) {
                tile.grabToImage(result => {
                    tile.Drag.imageSource = result.url
                    tile.Drag.active = true
                })
            } else {
                tile.Drag.active = false
            }
        }
    }

    // Tile card backdrop
    Rectangle {
        id: cardFrame
        anchors.fill: parent
        anchors.margins: Math.max(2, Math.round(Kirigami.Units.smallSpacing * 0.65))
        radius: root.cardRadius
        color: tile.activeState ? root.effectiveTileHoverColor : root.cardColor
        border.color: tile.activeState ? root.cardHoverBorderColor : root.cardBorderColor
        border.width: 1
        Behavior on color { ColorAnimation { duration: root.animShort } }
        Behavior on border.color { ColorAnimation { duration: root.animShort } }

        // Specular glass edge highlight on top rim (Spatial / HUD)
        Rectangle {
            visible: tile.activeState && !root.isClassic
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: Math.min(parent.radius, 12)
            anchors.rightMargin: Math.min(parent.radius, 12)
            height: 1
            color: root.specularColor
            opacity: 0.72
        }

        // Cyber-Tech corner micro-ticks on active card
        Rectangle {
            visible: root.isCyber && tile.activeState
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: -1
            anchors.leftMargin: -1
            width: 7
            height: 2
            color: root.effectiveAccent
        }
        Rectangle {
            visible: root.isCyber && tile.activeState
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: -1
            anchors.rightMargin: -1
            width: 7
            height: 2
            color: root.effectiveAccent
        }
    }

    // Luminous icon aura when hovered or focused
    Shape {
        visible: !root.isClassic
        anchors.centerIn: tileContent
        anchors.verticalCenterOffset: tile.showLabel ? -Kirigami.Units.smallSpacing : 0
        width: tile.iconSize * 1.65
        height: width
        opacity: tile.activeState ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: root.animShort } }
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: tile.iconSize * 0.825
                centerY: tile.iconSize * 0.825
                focalX: centerX
                focalY: centerY
                centerRadius: tile.iconSize * 0.825
                GradientStop {
                    position: 0.0
                    color: root.withAlpha(root.effectiveAccent, root.isDark ? 0.28 : 0.18)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
            PathAngleArc {
                centerX: tile.iconSize * 0.825
                centerY: tile.iconSize * 0.825
                radiusX: tile.iconSize * 0.825
                radiusY: tile.iconSize * 0.825
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Click pulse luminous ring effect
    Rectangle {
        id: clickPulse
        anchors.centerIn: parent
        width: 0
        height: 0
        radius: root.isCyber ? root.cardRadius : width / 2
        color: root.withAlpha(root.effectiveAccent, 0.14)
        border.width: 2
        border.color: root.effectiveAccent
        opacity: 0

        ParallelAnimation {
            id: pulseAnim
            NumberAnimation { target: clickPulse; property: "width"; from: 16; to: tile.width * 0.94; duration: Math.max(90, root.animShort * 1.35); easing.type: Easing.OutQuad }
            NumberAnimation { target: clickPulse; property: "height"; from: 16; to: tile.width * 0.94; duration: Math.max(90, root.animShort * 1.35); easing.type: Easing.OutQuad }
            NumberAnimation { target: clickPulse; property: "opacity"; from: 0.72; to: 0.0; duration: Math.max(90, root.animShort * 1.35); easing.type: Easing.OutQuad }
        }
    }

    Column {
        id: tileContent
        anchors.centerIn: parent
        spacing: Kirigami.Units.smallSpacing / 2

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: tile.iconSize
            height: tile.iconSize
            scale: tileMouse.pressed ? 0.88 : ((tile.activeState && root.animEffect !== 1) ? 1.07 : 1.0)
            Behavior on scale {
                NumberAnimation {
                    duration: root.animFast
                    easing.type: root.animEasingType
                    easing.overshoot: root.animOvershoot
                }
            }

            Kirigami.Icon {
                anchors.fill: parent
                source: tile.icon
                visible: !tile.imageReady
            }
            Image {
                id: img
                anchors.fill: parent
                source: tile.imageSource
                fillMode: Image.PreserveAspectFit
                visible: tile.imageReady
            }
        }

        QQC2.Label {
            visible: tile.showLabel && tile.label.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            width: tile.width - Kirigami.Units.smallSpacing * 2.4
            horizontalAlignment: Text.AlignHCenter
            text: tile.label
            color: root.effectiveTextColor
            opacity: tile.activeState ? 1.0 : 0.88
            font.weight: tile.activeState ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            maximumLineCount: 1
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            Behavior on opacity { NumberAnimation { duration: root.animShort } }
        }
    }

    QQC2.ToolTip.text: tile.tooltip
    QQC2.ToolTip.visible: tile.tooltip.length > 0 && tileMouse.containsMouse
    QQC2.ToolTip.delay: 600

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                tile.rightClicked()
            } else {
                if (root.animationsEnabled) {
                    pulseAnim.restart()
                }
                tile.clicked()
            }
        }
    }
}
