// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.iconthemes as KIconThemes
import Qt.labs.platform as Platform

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_backgroundOpacity: opacitySlider.value
    property alias cfg_iconSize: iconSizeSpin.value
    property alias cfg_showLabels: labelsCheck.checked
    property alias cfg_animationDuration: animDurationSlider.value
    property int cfg_animationEffect
    property alias cfg_enableAnimations: animCheck.checked
    property alias cfg_portraitMode: portraitCheck.checked
    property alias cfg_cornerRadius: radiusSpin.value
    property alias cfg_updateCommand: updateCmdField.text
    property alias cfg_webLinks: webLinksArea.text
    property int cfg_defaultPage
    property string cfg_icon
    property int cfg_iconMode
    property int cfg_iconColorSource
    property alias cfg_iconSaturation: satSlider.value
    property alias cfg_rippleContrastS: contrastSCheck.checked
    property alias cfg_rippleGlow: glowCheck.checked
    property var cfg_hiddenApplications: []
    property int cfg_visualTheme
    property alias cfg_showHudBar: hudBarCheck.checked
    property int cfg_accentColorMode
    property string cfg_customAccentColor
    property string cfg_customSurfaceColor
    property string cfg_customRibbonColor
    property string cfg_customRibbonBorderColor
    property string cfg_customTextColor
    property string cfg_customSearchBarColor
    property string cfg_customSearchBarBorderColor
    property string cfg_customTileHoverColor
    property int cfg_ribbonStyle
    property string cfg_customButtonColor

    readonly property bool isDarkTheme: {
        const bg = Kirigami.Theme.backgroundColor
        return (0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b) < 0.5
    }

    readonly property color previewAccent: {
        const mode = accentModeCombo.currentIndex
        const bg = Kirigami.Theme.backgroundColor
        switch (mode) {
        case 1: return configRoot.isDarkTheme ? Qt.color("#fbbf24") : Qt.color("#d97706")
        case 2: return configRoot.isDarkTheme ? Qt.color("#34d399") : Qt.color("#059669")
        case 3: return configRoot.isDarkTheme ? Qt.color("#a78bfa") : Qt.color("#7c3aed")
        case 4: return configRoot.isDarkTheme ? Qt.color("#fb7185") : Qt.color("#e11d48")
        case 5: return configRoot.isDarkTheme ? Qt.color("#2dd4bf") : Qt.color("#0d9488")
        case 6: return configRoot.isDarkTheme ? Qt.color("#cbd5e1") : Qt.color("#475569")
        case 7: return Kirigami.Theme.highlightColor
        case 8:
            const c = (configRoot.cfg_customAccentColor || "").trim()
            if (c.length > 0) {
                try { return Qt.color(c) } catch (e) {}
            }
            return configRoot.isDarkTheme ? Qt.color("#fbbf24") : Qt.color("#d97706")
        case 0:
        default:
            if (bg.hslSaturation > 0.08) {
                const sat = Math.min(1.0, Math.max(0.55, bg.hslSaturation * 1.6))
                const light = configRoot.isDarkTheme ? 0.72 : 0.36
                return Qt.hsla(bg.hslHue, sat, light, 1.0)
            }
            if (visualThemeCombo.currentIndex === 1) {
                return configRoot.isDarkTheme ? Qt.color("#38bdf8") : Qt.color("#0284c7")
            }
            if (visualThemeCombo.currentIndex === 2) {
                return configRoot.isDarkTheme ? Qt.color("#22d3ee") : Qt.color("#0891b2")
            }
            return configRoot.isDarkTheme ? Qt.color("#fbbf24") : Qt.color("#d97706")
        }
    }

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: portraitCheck
            Kirigami.FormData.label: i18n("Layout:")
            text: i18n("Portrait (phone-style)")
        }

        QQC2.ComboBox {
            id: defaultPageCombo
            Kirigami.FormData.label: i18n("Open on:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("All apps"), value: 0 },
                { text: i18n("Favourites"), value: 2 },
                { text: i18n("Recent apps"), value: 5 },
                { text: i18n("Documents"), value: 1 },
                { text: i18n("Places"), value: 4 },
                { text: i18n("Web links"), value: 6 },
                { text: i18n("Quick actions"), value: 3 }
            ]
            onActivated: configRoot.cfg_defaultPage = currentValue
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(configRoot.cfg_defaultPage))
        }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            Kirigami.FormData.label: i18n("Background opacity:")
            QQC2.Slider {
                id: opacitySlider
                from: 30
                to: 100
                stepSize: 5
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            QQC2.Label {
                text: i18n("%1%", opacitySlider.value)
            }
        }

        QQC2.SpinBox {
            id: iconSizeSpin
            Kirigami.FormData.label: i18n("Icon size:")
            from: 24
            to: 96
            stepSize: 8
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Hidden apps:")
            text: i18n("Unhide all applications")
            icon.name: "view-visible"
            enabled: (configRoot.cfg_hiddenApplications || []).length > 0
            onClicked: configRoot.cfg_hiddenApplications = []
        }

        QQC2.CheckBox {
            id: labelsCheck
            text: i18n("Show app names under icons")
        }

        QQC2.SpinBox {
            id: radiusSpin
            Kirigami.FormData.label: i18n("Corner radius:")
            from: 0
            to: 32
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Colours & Style")
        }

        QQC2.ComboBox {
            id: visualThemeCombo
            Kirigami.FormData.label: i18n("Future style:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            model: [
                i18n("Spatial Liquid Glass (frosted specular)"),
                i18n("Crystalline HUD (luminous trims)"),
                i18n("Cyber-Tech Neo-Minimal (geometric grid)"),
                i18n("Classic Adaptive")
            ]
            onActivated: configRoot.cfg_visualTheme = currentIndex
            Component.onCompleted: currentIndex = configRoot.cfg_visualTheme
        }

        Connections {
            target: configRoot
            function onCfg_visualThemeChanged() {
                if (visualThemeCombo.currentIndex !== configRoot.cfg_visualTheme) {
                    visualThemeCombo.currentIndex = configRoot.cfg_visualTheme
                }
            }
        }

        QQC2.CheckBox {
            id: hudBarCheck
            text: i18n("Show HUD status bar (clock, distro, live CPU & RAM)")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Accent palette:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.ComboBox {
                id: accentModeCombo
                Layout.preferredWidth: Kirigami.Units.gridUnit * 15
                model: [
                    i18n("Adaptive (adjusts with background)"),
                    i18n("Warm Amber"),
                    i18n("Emerald Mint"),
                    i18n("Royal Violet"),
                    i18n("Coral Rose"),
                    i18n("Modern Teal"),
                    i18n("Neutral Slate"),
                    i18n("System accent"),
                    i18n("Custom colour…")
                ]
                onActivated: configRoot.cfg_accentColorMode = currentIndex
                Component.onCompleted: currentIndex = configRoot.cfg_accentColorMode
            }

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: Layout.preferredWidth / 2
                color: configRoot.previewAccent
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }
        }

        QQC2.ComboBox {
            id: ribbonStyleCombo
            Kirigami.FormData.label: i18n("Ribbon style:")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            model: [
                i18n("Adaptive surface (adjusts with background)"),
                i18n("Subtle accent tint"),
                i18n("Solid accent"),
                i18n("Minimal glass")
            ]
            onActivated: configRoot.cfg_ribbonStyle = currentIndex
            Component.onCompleted: currentIndex = configRoot.cfg_ribbonStyle
        }

        QQC2.CheckBox {
            id: showCustomPaletteCheck
            text: i18n("Customize every individual colour")
            checked: accentModeCombo.currentIndex === 8
                || (configRoot.cfg_customSurfaceColor || "").length > 0
                || (configRoot.cfg_customRibbonColor || "").length > 0
                || (configRoot.cfg_customRibbonBorderColor || "").length > 0
                || (configRoot.cfg_customTextColor || "").length > 0
                || (configRoot.cfg_customSearchBarColor || "").length > 0
                || (configRoot.cfg_customSearchBarBorderColor || "").length > 0
                || (configRoot.cfg_customTileHoverColor || "").length > 0
        }

        // Custom accent colour row
        RowLayout {
            Kirigami.FormData.label: i18n("Accent colour:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customAccentField.text.trim()) return Qt.color(customAccentField.text.trim()) } catch(e) {}
                    return configRoot.previewAccent
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customAccentField
                text: configRoot.cfg_customAccentColor || ""
                placeholderText: i18n("Auto (#fbbf24)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customAccentColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customAccentField.text || configRoot.previewAccent, c => {
                    configRoot.cfg_customAccentColor = c
                    customAccentField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customAccentField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customAccentField.text = ""; configRoot.cfg_customAccentColor = "" }
            }
        }

        // Surface (window background)
        RowLayout {
            Kirigami.FormData.label: i18n("Window background:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customSurfaceField.text.trim()) return Qt.color(customSurfaceField.text.trim()) } catch(e) {}
                    return Kirigami.Theme.backgroundColor
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customSurfaceField
                text: configRoot.cfg_customSurfaceColor || ""
                placeholderText: i18n("Auto (theme background)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customSurfaceColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customSurfaceField.text || Kirigami.Theme.backgroundColor, c => {
                    configRoot.cfg_customSurfaceColor = c
                    customSurfaceField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customSurfaceField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customSurfaceField.text = ""; configRoot.cfg_customSurfaceColor = "" }
            }
        }

        // Ribbon background
        RowLayout {
            Kirigami.FormData.label: i18n("Ribbon background:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customRibbonField.text.trim()) return Qt.color(customRibbonField.text.trim()) } catch(e) {}
                    return configRoot.isDarkTheme ? Qt.rgba(0.2, 0.22, 0.25, 1) : Qt.rgba(0.92, 0.93, 0.95, 1)
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customRibbonField
                text: configRoot.cfg_customRibbonColor || ""
                placeholderText: i18n("Auto (adaptive surface)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customRibbonColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customRibbonField.text || Kirigami.Theme.backgroundColor, c => {
                    configRoot.cfg_customRibbonColor = c
                    customRibbonField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customRibbonField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customRibbonField.text = ""; configRoot.cfg_customRibbonColor = "" }
            }
        }

        // Ribbon border & divider
        RowLayout {
            Kirigami.FormData.label: i18n("Ribbon border:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customRibbonBorderField.text.trim()) return Qt.color(customRibbonBorderField.text.trim()) } catch(e) {}
                    return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.2)
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customRibbonBorderField
                text: configRoot.cfg_customRibbonBorderColor || ""
                placeholderText: i18n("Auto (subtle divider)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customRibbonBorderColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customRibbonBorderField.text || Kirigami.Theme.textColor, c => {
                    configRoot.cfg_customRibbonBorderColor = c
                    customRibbonBorderField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customRibbonBorderField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customRibbonBorderField.text = ""; configRoot.cfg_customRibbonBorderColor = "" }
            }
        }

        // Text & label colour
        RowLayout {
            Kirigami.FormData.label: i18n("Text & labels:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customTextField.text.trim()) return Qt.color(customTextField.text.trim()) } catch(e) {}
                    return Kirigami.Theme.textColor
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customTextField
                text: configRoot.cfg_customTextColor || ""
                placeholderText: i18n("Auto (theme text)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customTextColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customTextField.text || Kirigami.Theme.textColor, c => {
                    configRoot.cfg_customTextColor = c
                    customTextField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customTextField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customTextField.text = ""; configRoot.cfg_customTextColor = "" }
            }
        }

        // Search bar background
        RowLayout {
            Kirigami.FormData.label: i18n("Search bar background:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customSearchBarField.text.trim()) return Qt.color(customSearchBarField.text.trim()) } catch(e) {}
                    return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.08)
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customSearchBarField
                text: configRoot.cfg_customSearchBarColor || ""
                placeholderText: i18n("Auto (translucent)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customSearchBarColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customSearchBarField.text || Kirigami.Theme.backgroundColor, c => {
                    configRoot.cfg_customSearchBarColor = c
                    customSearchBarField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customSearchBarField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customSearchBarField.text = ""; configRoot.cfg_customSearchBarColor = "" }
            }
        }

        // Search bar border
        RowLayout {
            Kirigami.FormData.label: i18n("Search bar border:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customSearchBarBorderField.text.trim()) return Qt.color(customSearchBarBorderField.text.trim()) } catch(e) {}
                    return Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customSearchBarBorderField
                text: configRoot.cfg_customSearchBarBorderColor || ""
                placeholderText: i18n("Auto (subtle outline)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customSearchBarBorderColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customSearchBarBorderField.text || Kirigami.Theme.textColor, c => {
                    configRoot.cfg_customSearchBarBorderColor = c
                    customSearchBarBorderField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customSearchBarBorderField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customSearchBarBorderField.text = ""; configRoot.cfg_customSearchBarBorderColor = "" }
            }
        }

        // Tile hover background
        RowLayout {
            Kirigami.FormData.label: i18n("Tile hover background:")
            visible: showCustomPaletteCheck.checked
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customTileHoverField.text.trim()) return Qt.color(customTileHoverField.text.trim()) } catch(e) {}
                    return Qt.rgba(configRoot.previewAccent.r, configRoot.previewAccent.g, configRoot.previewAccent.b, 0.18)
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customTileHoverField
                text: configRoot.cfg_customTileHoverColor || ""
                placeholderText: i18n("Auto (soft accent)")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextChanged: configRoot.cfg_customTileHoverColor = text
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customTileHoverField.text || configRoot.previewAccent, c => {
                    configRoot.cfg_customTileHoverColor = c
                    customTileHoverField.text = c
                })
            }

            QQC2.ToolButton {
                icon.name: "edit-clear"
                visible: customTileHoverField.text.length > 0
                QQC2.ToolTip.text: i18n("Reset to auto")
                QQC2.ToolTip.visible: hovered
                onClicked: { customTileHoverField.text = ""; configRoot.cfg_customTileHoverColor = "" }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Animations")
        }

        QQC2.CheckBox {
            id: animCheck
            text: i18n("Enable smooth UI animations")
        }

        QQC2.ComboBox {
            id: animEffectCombo
            Kirigami.FormData.label: i18n("Animation effect:")
            enabled: animCheck.checked
            Layout.preferredWidth: Kirigami.Units.gridUnit * 15
            model: [
                i18n("Slide & Fade (smooth)"),
                i18n("Gentle Fade (no movement)"),
                i18n("Zoom & Fade"),
                i18n("Cascade Reveal"),
                i18n("Silky Glide (exponential)"),
                i18n("Soft Spring")
            ]
            onActivated: configRoot.cfg_animationEffect = currentIndex
            Component.onCompleted: currentIndex = configRoot.cfg_animationEffect
        }

        Connections {
            target: configRoot
            function onCfg_animationEffectChanged() {
                if (animEffectCombo.currentIndex !== configRoot.cfg_animationEffect) {
                    animEffectCombo.currentIndex = configRoot.cfg_animationEffect
                }
            }
            function onCfg_iconModeChanged() {
                if (iconModeCombo.currentIndex !== configRoot.cfg_iconMode) {
                    iconModeCombo.currentIndex = configRoot.cfg_iconMode
                }
            }
            function onCfg_accentColorModeChanged() {
                if (accentModeCombo.currentIndex !== configRoot.cfg_accentColorMode) {
                    accentModeCombo.currentIndex = configRoot.cfg_accentColorMode
                }
            }
            function onCfg_ribbonStyleChanged() {
                if (ribbonStyleCombo.currentIndex !== configRoot.cfg_ribbonStyle) {
                    ribbonStyleCombo.currentIndex = configRoot.cfg_ribbonStyle
                }
            }
            function onCfg_defaultPageChanged() {
                const idx = Math.max(0, defaultPageCombo.indexOfValue(configRoot.cfg_defaultPage))
                if (defaultPageCombo.currentIndex !== idx) {
                    defaultPageCombo.currentIndex = idx
                }
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Animation duration:")
            enabled: animCheck.checked
            spacing: Kirigami.Units.smallSpacing
            QQC2.Slider {
                id: animDurationSlider
                from: 150
                to: 1200
                stepSize: 25
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            QQC2.Label {
                text: i18n("%1 ms", Math.round(animDurationSlider.value))
                Layout.minimumWidth: Kirigami.Units.gridUnit * 4.5
            }
        }

        QQC2.Label {
            enabled: animCheck.checked
            opacity: 0.7
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            text: i18n("Applies to menu open/close, tab switches, categories, and popups (default: 440 ms).")
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextField {
            id: updateCmdField
            Kirigami.FormData.label: i18n("System update command:")
            placeholderText: i18n("Leave empty to auto-detect (nobara-sync, dnf, pacman, apt, zypper)")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextArea {
            id: webLinksArea
            Kirigami.FormData.label: i18n("Web links:")
            placeholderText: i18n("One per line: Label | https://url")
            wrapMode: TextEdit.NoWrap
            Layout.preferredWidth: Kirigami.Units.gridUnit * 22
            Layout.preferredHeight: Kirigami.Units.gridUnit * 8
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel button")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Button style:")
            spacing: Kirigami.Units.largeSpacing

            QQC2.ComboBox {
                id: iconModeCombo
                model: [
                    i18n("System icon or image"),
                    i18n("Launcher symbol — solid"),
                    i18n("Launcher symbol — ripples"),
                    i18n("Launcher symbol — Future Core")
                ]
                onActivated: configRoot.cfg_iconMode = currentIndex
                Component.onCompleted: currentIndex = configRoot.cfg_iconMode
            }

            // live preview of whatever is currently selected
            Item {
                Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                Layout.preferredHeight: Kirigami.Units.iconSizes.medium

                Kirigami.Icon {
                    anchors.fill: parent
                    visible: iconModeCombo.currentIndex === 0
                    source: configRoot.cfg_icon
                }
                LauncherIcon {
                    id: previewLauncherIcon
                    anchors.fill: parent
                    visible: iconModeCombo.currentIndex !== 0
                    ripples: iconModeCombo.currentIndex === 2
                    futureCore: iconModeCombo.currentIndex === 3
                    hovered: previewMouse.containsMouse
                    opened: previewMouse.previewOpen
                    contrastS: contrastSCheck.checked
                    glow: glowCheck.checked
                    color: {
                        let base
                        const src = iconColorCombo.currentIndex
                        if (src === 1) {
                            base = Kirigami.Theme.highlightColor
                        } else if (src === 2 && (configRoot.cfg_customButtonColor || "").trim().length > 0) {
                            try {
                                base = Qt.color(configRoot.cfg_customButtonColor.trim())
                            } catch (e) {
                                base = configRoot.previewAccent
                            }
                        } else if (src === 3) {
                            base = Qt.color("#3daee9")
                        } else {
                            base = configRoot.previewAccent
                        }
                        return Qt.hsla(base.hslHue,
                            Math.min(1, base.hslSaturation * satSlider.value),
                            base.hslLightness, 1)
                    }
                }
                MouseArea {
                    id: previewMouse
                    property bool previewOpen: false
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: previewOpen = !previewOpen
                }
            }
        }

        QQC2.Button {
            Kirigami.FormData.label: i18n("Icon:")
            visible: iconModeCombo.currentIndex === 0
            icon.name: configRoot.cfg_icon
            text: i18n("Choose…")
            onClicked: iconDialog.open()
        }

        QQC2.ComboBox {
            id: iconColorCombo
            Kirigami.FormData.label: i18n("Button colour:")
            visible: iconModeCombo.currentIndex > 0
            model: [
                i18n("Adaptive (follows launcher)"),
                i18n("System accent"),
                i18n("Custom colour…"),
                i18n("Classic blue")
            ]
            onActivated: configRoot.cfg_iconColorSource = currentIndex
            Component.onCompleted: currentIndex = configRoot.cfg_iconColorSource
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Custom button colour:")
            visible: iconModeCombo.currentIndex > 0 && iconColorCombo.currentIndex === 2
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Layout.preferredWidth
                radius: 4
                color: {
                    try { if (customButtonField.text.trim()) return Qt.color(customButtonField.text.trim()) } catch(e) {}
                    return configRoot.previewAccent
                }
                border.color: Kirigami.Theme.textColor
                border.width: 1
            }

            QQC2.TextField {
                id: customButtonField
                text: configRoot.cfg_customButtonColor || ""
                placeholderText: "#fbbf24"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 8
                onTextEdited: configRoot.cfg_customButtonColor = text
            }

            Connections {
                target: configRoot
                function onCfg_customButtonColorChanged() {
                    if (customButtonField.text !== configRoot.cfg_customButtonColor) {
                        customButtonField.text = configRoot.cfg_customButtonColor || ""
                    }
                }
            }

            QQC2.Button {
                text: i18n("Pick…")
                icon.name: "color-picker"
                onClicked: colorDialog.openFor(customButtonField.text || configRoot.previewAccent, c => {
                    configRoot.cfg_customButtonColor = c
                    customButtonField.text = c
                })
            }
        }

        QQC2.CheckBox {
            id: glowCheck
            visible: iconModeCombo.currentIndex >= 2
            text: i18n("Soft glow behind button")
        }

        QQC2.CheckBox {
            id: contrastSCheck
            visible: iconModeCombo.currentIndex >= 2
            text: i18n("White/black S (follows theme)")
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Colour saturation:")
            visible: iconModeCombo.currentIndex > 0
            QQC2.Slider {
                id: satSlider
                from: 1.0
                to: 4.0
                stepSize: 0.5
                Layout.preferredWidth: Kirigami.Units.gridUnit * 12
            }
            QQC2.Label {
                text: i18n("%1x", satSlider.value.toFixed(2))
            }
        }
    }

    KIconThemes.IconDialog {
        id: iconDialog
        onIconNameChanged: configRoot.cfg_icon = iconName
    }

    Platform.ColorDialog {
        id: colorDialog
        title: i18n("Choose colour")
        property var colorCallback: null

        function openFor(initialCol, callback) {
            colorCallback = callback
            try {
                currentColor = Qt.color(initialCol.toString())
            } catch (e) {
                currentColor = Kirigami.Theme.highlightColor
            }
            open()
        }

        onAccepted: {
            if (colorCallback) {
                colorCallback(currentColor.toString())
            }
        }
    }
}
