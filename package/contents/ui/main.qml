// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.kicker as Kicker
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 10

    Plasmoid.icon: Plasmoid.configuration.icon

    // Animation timing & effect curve driven by user settings
    readonly property bool animationsEnabled: Plasmoid.configuration.enableAnimations
    readonly property int animEffect: Plasmoid.configuration.animationEffect
    readonly property int animDuration: animationsEnabled ? Math.max(120, Plasmoid.configuration.animationDuration) : 0
    readonly property int animFast: animationsEnabled ? Math.max(100, Math.round(animDuration * 0.68)) : 0
    readonly property int animShort: animFast
    readonly property int animLong: animDuration
    readonly property int animEasingType: {
        switch (animEffect) {
        case 1: return Easing.OutQuad
        case 4: return Easing.OutExpo
        case 5: return Easing.OutBack
        case 0:
        case 2:
        case 3:
        default: return Easing.OutCubic
        }
    }
    readonly property real animOvershoot: animEffect === 5 ? 1.15 : 1.0

    // Shared app data models (Kicker backend — same engine Kickoff uses)
    property alias rootModel: rootModel
    property alias runnerModel: runnerModel

    // diagnostics — reachable as root.logger from any page
    property alias logger: logger
    Logger { id: logger }

    Kicker.RootModel {
        id: rootModel
        autoPopulate: false
        appNameFormat: 0
        // flat: merge sub-menus (Card Games, Debuggers…) into their top-level
        // category so the grid never shows folder entries that don't launch
        flat: true
        sorted: true
        showSeparators: false
        showAllAppsCategorized: false
        showRecentApps: false
        showRecentDocs: false
        showPowerSession: false
        // adds an "All Applications" row (flat A-Z list of everything)
        // that AppsPage pins as the first category tab
        showAllApps: true
        appletInterface: root

        Component.onCompleted: {
            favoritesModel.initForClient("org.kde.plasma.kickoff.favorites.instance-" + Plasmoid.id)
            if (!Plasmoid.configuration.favoritesPortedToKAstats) {
                if (favoritesModel.count < 1) {
                    favoritesModel.portOldFavorites(Plasmoid.configuration.favorites)
                }
                Plasmoid.configuration.favoritesPortedToKAstats = true
            }
            rootModel.refresh()
        }
    }

    Connections {
        target: rootModel.favoritesModel
        function onFavoritesChanged() {
            Plasmoid.configuration.favorites = rootModel.favoritesModel.favorites
        }
    }

    Kicker.RunnerModel {
        id: runnerModel
        appletInterface: root
        favoritesModel: rootModel.favoritesModel
        mergeResults: true
    }

    Kicker.SystemModel {
        id: systemModel
        favoritesModel: rootModel.systemFavoritesModel
    }
    property alias systemModel: systemModel

    // allow Plasma's global-shortcut activation (Meta key / panel
    // shortcut) to toggle the launcher like the stock ones do
    Component.onCompleted: {
        if (root.hasOwnProperty("activationTogglesExpanded")) {
            root.activationTogglesExpanded = true
        } else if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
            Plasmoid.activationTogglesExpanded = true
        }
    }

    P5Support.DataSource {
        id: executor
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            // surface anything that fell over instead of swallowing it
            const code = data["exit code"]
            if (code !== undefined && code !== 0) {
                const err = (data.stderr || "").trim()
                logger.error("command exited " + code + ": " + sourceName
                    + (err.length > 0 ? " — " + err : ""))
            }
            disconnectSource(sourceName)
        }
    }
    function execCmd(cmd) {
        if (cmd && cmd.length > 0) {
            executor.connectSource(cmd)
        } else {
            logger.warn("execCmd called with an empty command")
        }
    }

    // ---- distro-aware system update command ----
    // probes /etc/os-release once; an explicit updateCommand in settings
    // always wins over detection
    property string detectedDistro: ""
    property string distroLabel: ""
    readonly property string detectedUpdateCmd: {
        const d = detectedDistro
        const wrap = c => "konsole -e sh -c '" + c
            + "; echo; echo Update finished. Press Enter to close.; read -r _'"
        if (d.includes("nobara")) return wrap("nobara-sync cli")
        if (d.includes("fedora") || d.includes("rhel") || d.includes("centos")) return wrap("sudo dnf upgrade --refresh")
        if (d.includes("arch") || d.includes("manjaro") || d.includes("cachyos") || d.includes("endeavour")) return wrap("sudo pacman -Syu")
        if (d.includes("suse")) return wrap("sudo zypper refresh && sudo zypper dup")
        if (d.includes("debian") || d.includes("ubuntu") || d.includes("mint") || d.includes("pop")) return wrap("sudo apt update && sudo apt full-upgrade")
        return wrap("echo No update command known for this distro. Set one in launcher settings.")
    }
    readonly property string effectiveUpdateCmd:
        Plasmoid.configuration.updateCommand.trim().length > 0
            ? Plasmoid.configuration.updateCommand
            : detectedUpdateCmd

    P5Support.DataSource {
        id: distroProbe
        engine: "executable"
        connectedSources: [". /etc/os-release 2>/dev/null; printf '%s|%s %s' \"${NAME:-$ID}\" \"${ID}\" \"${ID_LIKE}\""]
        onNewData: (sourceName, data) => {
            const raw = (data.stdout || "").trim()
            const sep = raw.indexOf("|")
            if (sep > -1) {
                root.distroLabel = raw.slice(0, sep).trim()
                root.detectedDistro = raw.slice(sep + 1).trim().toLowerCase()
            } else {
                root.detectedDistro = raw.toLowerCase()
            }
            disconnectSource(sourceName)
        }
    }

    // ---- Future visual theme engine ----
    // 0: Spatial Liquid Glass | 1: Crystalline HUD | 2: Cyber-Tech Neo-Minimal | 3: Classic Adaptive
    readonly property int visualTheme: Plasmoid.configuration.visualTheme
    readonly property bool showHudBar: Plasmoid.configuration.showHudBar
    readonly property bool isSpatial: visualTheme === 0
    readonly property bool isHud: visualTheme === 1
    readonly property bool isCyber: visualTheme === 2
    readonly property bool isClassic: visualTheme === 3

    // ---- View layout mode: 0 = Grid | 1 = List (icon left) | 2 = Compact Grid ----
    readonly property int appViewMode: Plasmoid.configuration.appViewMode
    readonly property bool isListView: appViewMode === 1
    readonly property bool isCompactGrid: appViewMode === 2

    function withAlpha(col, alpha) {
        return Qt.rgba(col.r, col.g, col.b, alpha)
    }

    function blendColors(c1, c2, t) {
        const k = Math.max(0.0, Math.min(1.0, t))
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * k,
            c1.g + (c2.g - c1.g) * k,
            c1.b + (c2.b - c1.b) * k,
            c1.a + (c2.a - c1.a) * k
        )
    }

    // Lightness & dark mode detection based on theme background color
    readonly property bool isDark: {
        const bg = Kirigami.Theme.backgroundColor
        return (0.2126 * bg.r + 0.7152 * bg.g + 0.0722 * bg.b) < 0.5
    }

    // Resolves launcher accent colour according to accentColorMode
    readonly property color effectiveAccent: {
        const mode = Plasmoid.configuration.accentColorMode
        const bg = Kirigami.Theme.backgroundColor
        switch (mode) {
        case 1: // Warm Amber
            return root.isDark ? Qt.color("#fbbf24") : Qt.color("#d97706")
        case 2: // Emerald Mint
            return root.isDark ? Qt.color("#34d399") : Qt.color("#059669")
        case 3: // Royal Violet
            return root.isDark ? Qt.color("#a78bfa") : Qt.color("#7c3aed")
        case 4: // Coral Rose
            return root.isDark ? Qt.color("#fb7185") : Qt.color("#e11d48")
        case 5: // Modern Teal
            return root.isDark ? Qt.color("#2dd4bf") : Qt.color("#0d9488")
        case 6: // Neutral Slate
            return root.isDark ? Qt.color("#cbd5e1") : Qt.color("#475569")
        case 7: // System Accent
            return Kirigami.Theme.highlightColor
        case 8: // Custom Hex
            const custom = (Plasmoid.configuration.customAccentColor || "").trim()
            if (custom.length > 0) {
                try {
                    return Qt.color(custom)
                } catch (e) {
                    // fallback
                }
            }
            return root.isDark ? Qt.color("#fbbf24") : Qt.color("#d97706")
        case 0: // Adaptive (adjusts with background colour)
        default:
            // If background has a distinct hue/tint, harmonize with it
            if (bg.hslSaturation > 0.08) {
                const sat = Math.min(1.0, Math.max(0.55, bg.hslSaturation * 1.6))
                const light = root.isDark ? 0.72 : 0.36
                return Qt.hsla(bg.hslHue, sat, light, 1.0)
            }
            // Theme-harmonized adaptive defaults for neutral backgrounds
            if (root.isHud) {
                return root.isDark ? Qt.color("#38bdf8") : Qt.color("#0284c7")
            }
            if (root.isCyber) {
                return root.isDark ? Qt.color("#22d3ee") : Qt.color("#0891b2")
            }
            return root.isDark ? Qt.color("#fbbf24") : Qt.color("#d97706")
        }
    }

    readonly property color effectiveTextColor: {
        const c = (Plasmoid.configuration.customTextColor || "").trim()
        if (c.length > 0) {
            try { return Qt.color(c) } catch (e) {}
        }
        return Kirigami.Theme.textColor
    }

    readonly property color effectiveTileHoverColor: {
        const c = (Plasmoid.configuration.customTileHoverColor || "").trim()
        if (c.length > 0) {
            try { return Qt.color(c) } catch (e) {}
        }
        const alpha = root.isHud ? (root.isDark ? 0.22 : 0.14)
                    : (root.isCyber ? (root.isDark ? 0.20 : 0.13) : (root.isDark ? 0.18 : 0.12))
        return withAlpha(root.effectiveAccent, alpha)
    }

    readonly property int effectiveRadius: root.isCyber
        ? Math.min(Plasmoid.configuration.cornerRadius, 8)
        : Plasmoid.configuration.cornerRadius
    readonly property int cardRadius: root.isCyber
        ? Math.max(3, Math.round(effectiveRadius * 0.55))
        : Math.max(8, Math.round(effectiveRadius * 0.75))
    readonly property int pillRadius: root.isCyber
        ? Math.max(4, Math.round(effectiveRadius * 0.5))
        : 999
    readonly property color specularColor: root.isDark
        ? Qt.rgba(1, 1, 1, root.isHud ? 0.22 : (root.isCyber ? 0.14 : 0.18))
        : Qt.rgba(1, 1, 1, 0.75)
    readonly property color cardColor: root.isClassic
        ? "transparent"
        : withAlpha(root.effectiveTextColor, root.isDark ? (root.isHud ? 0.055 : 0.045) : 0.035)
    readonly property color cardBorderColor: root.isClassic
        ? "transparent"
        : (root.isCyber
            ? withAlpha(root.effectiveAccent, root.isDark ? 0.26 : 0.20)
            : (root.isHud
                ? withAlpha(root.effectiveAccent, root.isDark ? 0.22 : 0.16)
                : withAlpha(root.effectiveTextColor, root.isDark ? 0.10 : 0.08)))
    readonly property color cardHoverBorderColor: withAlpha(
        root.effectiveAccent,
        root.isCyber ? (root.isDark ? 0.72 : 0.52)
                     : (root.isHud ? (root.isDark ? 0.60 : 0.44) : (root.isDark ? 0.44 : 0.30))
    )
    readonly property color shellBorderColor: root.isHud
        ? withAlpha(root.effectiveAccent, root.isDark ? 0.42 : 0.28)
        : (root.isCyber
            ? withAlpha(root.effectiveAccent, root.isDark ? 0.55 : 0.38)
            : (root.isSpatial
                ? (root.isDark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.65))
                : withAlpha(root.effectiveTextColor, 0.12)))

    // Track launcher closing state on root so compactRepresentation's LauncherIcon
    // can react without referencing ids inside the lazy fullRepresentation Component.
    property bool closingLauncher: false
    property var fullRepInstance: null

    compactRepresentation: MouseArea {
        id: compactRoot
        hoverEnabled: true
        onClicked: {
            if (root.expanded) {
                root.closeLauncher()
            } else {
                root.expanded = true
            }
        }

        // 0 = system icon / custom image, 1 = launcher mark solid, 2 = launcher mark ripples, 3 = launcher mark Future Core
        readonly property int iconMode: Plasmoid.configuration.iconMode
        readonly property color launcherIconColor: {
            // Qt.color() wrap matters: a bare string has no hsl* members,
            // which fed NaN into Qt.hsla and rendered black
            let base
            const src = Plasmoid.configuration.iconColorSource
            if (src === 1) {
                base = Kirigami.Theme.highlightColor
            } else if (src === 2 && (Plasmoid.configuration.customButtonColor || "").trim().length > 0) {
                try {
                    base = Qt.color(Plasmoid.configuration.customButtonColor.trim())
                } catch (e) {
                    base = root.effectiveAccent
                }
            } else if (src === 3) {
                base = Qt.color("#3daee9")
            } else {
                // src === 0: Adaptive / follows launcher accent
                base = root.effectiveAccent
            }
            // optional saturation boost so a dull system accent can pop
            const sat = Math.min(1, base.hslSaturation * Plasmoid.configuration.iconSaturation)
            return Qt.hsla(base.hslHue, sat, base.hslLightness, 1)
        }

        Kirigami.Icon {
            anchors.fill: parent
            visible: compactRoot.iconMode === 0
            source: Plasmoid.configuration.icon
            active: compactRoot.containsMouse
        }

        LauncherIcon {
            anchors.fill: parent
            visible: compactRoot.iconMode !== 0
            ripples: compactRoot.iconMode === 2
            futureCore: compactRoot.iconMode === 3
            opened: root.expanded && !root.closingLauncher
            color: compactRoot.launcherIconColor
            contrastS: Plasmoid.configuration.rippleContrastS
            glow: Plasmoid.configuration.rippleGlow
            hovered: compactRoot.containsMouse
        }
    }

    function closeLauncher(callback) {
        const fr = root.fullRepresentationItem || root.fullRepInstance
        if (root.animationsEnabled && fr && fr.closeWithAnimation) {
            fr.closeWithAnimation(callback)
        } else {
            root.closingLauncher = false
            if (callback) callback()
            root.expanded = false
        }
    }

    fullRepresentation: FullRepresentation {}
}
