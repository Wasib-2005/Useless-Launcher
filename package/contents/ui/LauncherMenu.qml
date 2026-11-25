// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Popup menu that follows the user's configured animation duration, effect,
// and Future glass/tech surface styling across every menu in the launcher.
QQC2.Menu {
    id: launcherMenu

    padding: Math.max(4, Kirigami.Units.smallSpacing)

    readonly property real entryStartScale: {
        if (!root.animationsEnabled || root.animEffect === 1) return 1.0
        if (root.animEffect === 2 || root.animEffect === 5) return 0.84
        return 0.90
    }
    readonly property real exitEndScale: (!root.animationsEnabled || root.animEffect === 1) ? 1.0 : 0.90

    background: Rectangle {
        implicitWidth: Kirigami.Units.gridUnit * 11
        radius: root.cardRadius
        color: root.blendColors(
            Kirigami.Theme.backgroundColor,
            root.isDark ? Qt.color("#0b0f17") : Qt.color("#ffffff"),
            root.isDark ? 0.35 : 0.25
        )
        opacity: 0.96
        border.width: 1
        border.color: root.isCyber || root.isHud
            ? root.withAlpha(root.effectiveAccent, 0.48)
            : root.shellBorderColor

        // Subtle top specular hairline
        Rectangle {
            visible: !root.isClassic
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: parent.radius
            anchors.rightMargin: parent.radius
            height: 1
            color: root.specularColor
            opacity: 0.55
        }
    }

    function clearAllItems() {
        while (count > 0) {
            const it = itemAt(0)
            removeItem(it)
            if (it) it.destroy()
        }
    }

    // Populates this menu (and nested submenus) from a Kicker actionList array.
    function populateActions(items, onTrigger) {
        clearAllItems()
        fillItems(launcherMenu, items, onTrigger)
    }

    function fillItems(targetMenu, items, onTrigger) {
        for (const a of items) {
            if (a.type === "separator") {
                targetMenu.addItem(sepComp.createObject(targetMenu))
            } else if (a.subActions) {
                const subComp = Qt.createComponent(Qt.resolvedUrl("LauncherMenu.qml"))
                const sub = subComp.createObject(targetMenu, { title: a.text ?? "" })
                if (sub) {
                    fillItems(sub, a.subActions, onTrigger)
                    targetMenu.addMenu(sub)
                }
            } else {
                const mi = itemComp.createObject(targetMenu, {
                    actionItem: a,
                    triggerHandler: onTrigger
                })
                targetMenu.addItem(mi)
            }
        }
    }

    Component {
        id: itemComp
        LauncherMenuItem {
            property var actionItem
            property var triggerHandler
            text: actionItem.text ?? ""
            icon.name: typeof actionItem.icon === "string" ? actionItem.icon : ""
            enabled: actionItem.type !== "title" && (actionItem.enabled ?? true)
            checkable: actionItem.checkable ?? false
            checked: actionItem.checked ?? false
            onTriggered: if (triggerHandler) triggerHandler(actionItem)
        }
    }

    Component {
        id: sepComp
        QQC2.MenuSeparator {
            contentItem: Rectangle {
                implicitHeight: 1
                color: root.withAlpha(root.effectiveTextColor, root.isDark ? 0.14 : 0.10)
            }
        }
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: root.animFast
                easing.type: root.animEasingType
                easing.overshoot: root.animOvershoot
            }
            NumberAnimation {
                property: "scale"
                from: launcherMenu.entryStartScale
                to: 1.0
                duration: root.animFast
                easing.type: root.animEasingType
                easing.overshoot: root.animOvershoot
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: root.animationsEnabled ? Math.max(50, Math.round(root.animFast * 0.75)) : 0
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                property: "scale"
                from: 1.0
                to: launcherMenu.exitEndScale
                duration: root.animationsEnabled ? Math.max(50, Math.round(root.animFast * 0.75)) : 0
                easing.type: Easing.InQuad
            }
        }
    }
}
