// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.coreaddons as KCoreAddons
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.plasma5support as P5Support

Item {
    id: fullRep

    // Single-timeline open/close drivers so elements never flash before starting
    property real openProgress: 1.0
    property real closeProgress: 0.0
    property var closeCallback: null

    // Live HUD telemetry state (only polled while launcher is expanded)
    property real prevCpuTotal: 0
    property real prevCpuIdle: 0
    property int cpuPercent: -1
    property int ramPercent: -1


    function clamp01(v) { return v <= 0.0 ? 0.0 : (v >= 1.0 ? 1.0 : v) }

    function applyEase(t, eff) {
        if (t <= 0.0) return 0.0
        if (t >= 1.0) return 1.0
        const u = 1.0 - t
        switch (eff) {
        case 1: return 1.0 - u * u
        case 4: return t >= 1.0 ? 1.0 : 1.0 - Math.pow(2.0, -10.0 * t)
        case 5: {
            const s = 0.75
            const b = t - 1.0
            return b * b * ((s + 1.0) * b + s) + 1.0
        }
        default: return 1.0 - u * u * u
        }
    }

    function applyCloseEase(t) {
        if (t <= 0.0) return 0.0
        if (t >= 1.0) return 1.0
        // Smooth release from frame 0 rather than staying invisible for the first half
        return t * (1.4 - 0.4 * t)
    }

    readonly property int eff: root.animEffect

    // ---- 3-phase cinematic open timeline ----
    // Phase 1  [0.00 → 0.40] : background scales up + avatar rises
    // Phase 2  [0.08 → 0.68] : top & left ribbons scroll in; search bar rises from bottom
    // Phase 3  [0.50 → 1.00] : content area fades in
    // eff === 1 (Instant) collapses all phases to a single simultaneous linear sweep.
    readonly property real tShell: eff === 1
        ? applyEase(openProgress, 1)
        : applyEase(clamp01(openProgress / 0.40), 0)
    readonly property real tAvatar: eff === 1
        ? applyEase(openProgress, 1)
        : applyEase(clamp01(openProgress / 0.44), 0)
    readonly property real tRibbons: eff === 1
        ? applyEase(openProgress, 1)
        : applyEase(clamp01((openProgress - 0.08) / 0.60), 0)
    readonly property real tSearch: eff === 1
        ? applyEase(openProgress, 1)
        : applyEase(clamp01((openProgress - 0.08) / 0.58), 0)
    readonly property real tBody: eff === 1
        ? applyEase(openProgress, 1)
        : applyEase(clamp01((openProgress - 0.50) / 0.50), 0)
    readonly property real cEase: applyCloseEase(closeProgress)

    // Derived properties bound by ribbons, nav items, content, and search bar
    // Ribbon items use pure tRibbons/tBody — the ribbon Items themselves carry the cEase fade
    readonly property real navMenuOpacity: tRibbons
    readonly property real bottomNavOpacity: tBody
    function navItemSlideY(idx) {
        if (eff === 1 || eff === 2) return 0.0
        const baseVert = (eff === 3 || eff === 4) ? (Kirigami.Units.gridUnit * 5.2) : (Kirigami.Units.gridUnit * 4.2)
        const stagger = idx * Kirigami.Units.gridUnit * 0.55
        const openOff = -(baseVert + stagger) * (1.0 - tRibbons)
        const closeOff = -(Kirigami.Units.gridUnit * 3.0 + idx * Kirigami.Units.gridUnit * 0.3) * cEase
        return openOff + closeOff
    }
    readonly property real navMenuScale: {
        const openScale = eff === 2 ? (0.84 + 0.16 * tRibbons) : (eff === 1 ? 1.0 : (0.92 + 0.08 * tRibbons))
        const closeScale = eff === 2 ? (1.0 - 0.08 * cEase) : (eff === 1 ? 1.0 : (1.0 - 0.04 * cEase))
        return openScale * closeScale
    }

    opacity: 1.0 - cEase

    readonly property bool portrait: Plasmoid.configuration.portraitMode
    readonly property int radius: root.effectiveRadius
    readonly property bool isDark: root.isDark
    readonly property color accent: root.effectiveAccent
    readonly property int ribbonStyle: Plasmoid.configuration.ribbonStyle
    readonly property color surface: {
        const c = (Plasmoid.configuration.customSurfaceColor || "").trim()
        if (c.length > 0) {
            try { return Qt.color(c) } catch (e) {}
        }
        return Qt.rgba(
            Kirigami.Theme.backgroundColor.r,
            Kirigami.Theme.backgroundColor.g,
            Kirigami.Theme.backgroundColor.b,
            Plasmoid.configuration.backgroundOpacity / 100)
    }

    readonly property color textColor: root.effectiveTextColor

    readonly property color ribbonColor: {
        const custom = (Plasmoid.configuration.customRibbonColor || "").trim()
        if (custom.length > 0) {
            try { return Qt.color(custom) } catch (e) {}
        }
        if (ribbonStyle === 2) {
            return fullRep.accent
        }
        if (ribbonStyle === 3) {
            return "transparent"
        }
        const bg = Kirigami.Theme.backgroundColor
        let baseSurface
        if (fullRep.isDark) {
            // Elevated dark surface that adjusts with background colour
            baseSurface = Qt.rgba(
                Math.min(1.0, bg.r + (1.0 - bg.r) * (root.isCyber ? 0.05 : 0.08)),
                Math.min(1.0, bg.g + (1.0 - bg.g) * (root.isCyber ? 0.05 : 0.08)),
                Math.min(1.0, bg.b + (1.0 - bg.b) * (root.isCyber ? 0.05 : 0.08)),
                Math.min(1.0, (Plasmoid.configuration.backgroundOpacity / 100) + 0.12)
            )
        } else {
            // Clean softly contrasted light surface that adjusts with background colour
            baseSurface = Qt.rgba(
                Math.max(0.0, bg.r * 0.95),
                Math.max(0.0, bg.g * 0.95),
                Math.max(0.0, bg.b * 0.95),
                Math.min(1.0, (Plasmoid.configuration.backgroundOpacity / 100) + 0.08)
            )
        }
        if (ribbonStyle === 1) {
            return Qt.tint(baseSurface, root.withAlpha(fullRep.accent, 0.13))
        }
        if (root.isHud) {
            return Qt.tint(baseSurface, root.withAlpha(fullRep.accent, 0.06))
        }
        return baseSurface
    }

    readonly property color ribbonBorderColor: {
        const custom = (Plasmoid.configuration.customRibbonBorderColor || "").trim()
        if (custom.length > 0) {
            try { return Qt.color(custom) } catch (e) {}
        }
        if (ribbonStyle === 2) {
            return fullRep.accent
        }
        if (ribbonStyle === 1) {
            return root.withAlpha(fullRep.accent, isDark ? 0.38 : 0.28)
        }
        if (ribbonStyle === 3) {
            return root.withAlpha(fullRep.textColor, 0.10)
        }
        if (root.isHud) {
            return root.withAlpha(fullRep.accent, isDark ? 0.34 : 0.24)
        }
        if (root.isCyber) {
            return root.withAlpha(fullRep.accent, isDark ? 0.42 : 0.30)
        }
        if (root.isSpatial) {
            return isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.55)
        }
        return root.withAlpha(fullRep.textColor, isDark ? 0.12 : 0.09)
    }

    readonly property color searchBarColor: {
        const c = (Plasmoid.configuration.customSearchBarColor || "").trim()
        if (c.length > 0) {
            try { return Qt.color(c) } catch (e) {}
        }
        const activeAlpha = root.isHud || root.isCyber ? (fullRep.isDark ? 0.12 : 0.07) : (fullRep.isDark ? 0.10 : 0.06)
        const idleAlpha = root.isClassic ? (fullRep.isDark ? 0.05 : 0.03) : (fullRep.isDark ? 0.075 : 0.045)
        return root.withAlpha(fullRep.textColor, searchField.activeFocus ? activeAlpha : idleAlpha)
    }

    readonly property color searchBarBorderColor: {
        const c = (Plasmoid.configuration.customSearchBarBorderColor || "").trim()
        if (c.length > 0) {
            try { return Qt.color(c) } catch (e) {}
        }
        return searchField.activeFocus
            ? fullRep.accent
            : (root.isCyber
                ? root.withAlpha(fullRep.accent, fullRep.isDark ? 0.32 : 0.24)
                : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.16 : 0.11))
    }

    readonly property int ribbonSize: Kirigami.Units.gridUnit * 3

    // contrast colour for icons sitting on the accent ribbon — the theme's
    // backgroundColor can be nearly the same shade as the accent, so pick
    // black/white by the accent's own luminance instead
    readonly property real accentLum: 0.2126 * accent.r + 0.7152 * accent.g + 0.0722 * accent.b
    readonly property color onAccent: accentLum > 0.55 ? Qt.rgba(0, 0, 0, 0.9) : Qt.rgba(1, 1, 1, 0.95)

    implicitWidth: portrait ? Kirigami.Units.gridUnit * 22 : Kirigami.Units.gridUnit * 38
    implicitHeight: portrait ? Kirigami.Units.gridUnit * 39 : Kirigami.Units.gridUnit * 30

    Layout.minimumWidth: Kirigami.Units.gridUnit * 18
    Layout.minimumHeight: Kirigami.Units.gridUnit * 22
    Layout.maximumWidth: Kirigami.Units.gridUnit * 60
    Layout.maximumHeight: Kirigami.Units.gridUnit * 60

    // KUser only reads account data at creation, so it lives in a Loader we
    // can bounce on each open — picks up avatar changes without a restart
    Loader {
        id: kuser
        sourceComponent: KCoreAddons.KUser {}
    }

    // Lightweight HUD telemetry probe (runs only while launcher is open)
    P5Support.DataSource {
        id: hudProbe
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
            fullRep.parseHudTelemetry(data.stdout || "")
        }
    }

    function parseHudTelemetry(stdout) {
        const lines = stdout.split("\n")
        let memTotal = 0
        let memAvail = 0
        for (const raw of lines) {
            const line = raw.trim()
            if (line.startsWith("cpu ")) {
                const parts = line.split(/\s+/)
                if (parts.length >= 5) {
                    let total = 0
                    for (let i = 1; i < parts.length; i++) {
                        const n = Number(parts[i])
                        if (!isNaN(n)) total += n
                    }
                    const idle = (Number(parts[4]) || 0) + (Number(parts[5]) || 0)
                    if (prevCpuTotal > 0 && total > prevCpuTotal) {
                        const dTotal = total - prevCpuTotal
                        const dIdle = idle - prevCpuIdle
                        cpuPercent = Math.max(0, Math.min(100, Math.round(100 * (1 - dIdle / dTotal))))
                    }
                    prevCpuTotal = total
                    prevCpuIdle = idle
                }
            } else if (line.startsWith("MemTotal:")) {
                memTotal = parseInt(line.replace(/[^0-9]/g, ""), 10) || 0
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = parseInt(line.replace(/[^0-9]/g, ""), 10) || 0
            }
        }
        if (memTotal > 0) {
            ramPercent = Math.max(0, Math.min(100, Math.round(100 * (memTotal - memAvail) / memTotal)))
        }
    }

    function refreshHudTelemetry() {
        hudProbe.connectSource("head -n 1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo")
    }

    Timer {
        id: hudTimer
        interval: 2500
        repeat: true
        triggeredOnStart: true
        running: root.expanded && root.showHudBar
        onTriggered: fullRep.refreshHudTelemetry()
    }

    // which page is shown: 0 apps, 1 docs, 2 favourites, 3 quick actions,
    // 4 places, 5 recent apps, 6 web links
    // always lands on the configured start page when opened fresh
    property int currentPage: Plasmoid.configuration.defaultPage

    // ---- nav ribbon items + overflow ----
    // Settings and Power are pinned at the bottom and always visible; these
    // page buttons fill from the top and collapse into a "⋯" menu when the
    // ribbon is too short for all of them
    readonly property var navItems: [
        { icon: "favorite", label: i18n("Favourites"), page: 2 },
        { icon: "view-grid-symbolic", label: i18n("All apps"), page: 0 },
        { icon: "view-history", label: i18n("Recent apps"), page: 5 },
        { icon: "folder-symbolic", label: i18n("Documents"), page: 1 },
        { icon: "drive-harddisk-symbolic", label: i18n("Places"), page: 4 },
        { icon: "internet-web-browser", label: i18n("Web links"), page: 6 },
        { icon: "system-run-symbolic", label: i18n("Quick actions"), page: 3 }
    ]
    readonly property int navBtnSize: ribbonSize - Kirigami.Units.smallSpacing * 2
    readonly property int navSpacing: Math.max(2, Math.round(Kirigami.Units.smallSpacing / 2))
    readonly property int navSlots: Math.max(0, Math.floor(
        (leftRibbon.height
         - navColumn.anchors.topMargin - navColumn.anchors.bottomMargin
         - (navBtnSize + navSpacing) * 2)               // pinned settings + power
        / (navBtnSize + navSpacing)))
    readonly property int visibleNavCount: navSlots >= navItems.length
        ? navItems.length
        : Math.max(0, navSlots - 1)                     // reserve a slot for ⋯
    readonly property var overflowNavItems: navItems.slice(visibleNavCount)
    readonly property bool searching: searchField.text.length > 0

    function reset() {
        searchField.text = ""
        currentPage = Plasmoid.configuration.defaultPage
        // re-read account name/avatar; the item swap also forces the face
        // image to reload from disk (source goes "" -> url)
        kuser.active = false
        kuser.active = true
        if (root.showHudBar) {
            refreshHudTelemetry()
        }
    }

    // typing while a grid has focus jumps back into search
    function typeAhead(text) {
        searchField.forceActiveFocus()
        searchField.text += text
    }

    // move keyboard focus from the search bar into the visible page
    function focusContent() {
        if (searching) {
            searchPage.focusResults()
            return
        }
        switch (currentPage) {
        case 0: appsPage.focusContent(); break
        case 1: docsPage.focusContent(); break
        case 2: favsPage.focusContent(); break
        case 3: quickPage.focusContent(); break
        case 4: placesPage.focusContent(); break
        case 5: recentAppsPage.focusContent(); break
        case 6: linksPage.focusContent(); break
        }
    }

    function closeWithAnimation(callback) {
        if (closeAnim.running) {
            return
        }
        if (!root.animationsEnabled) {
            root.closingLauncher = false
            if (callback) callback()
            root.expanded = false
            return
        }
        entranceAnim.stop()
        root.closingLauncher = true
        closeCallback = callback || null
        closeProgress = 0.0
        closeAnim.restart()
    }

    function startOpenAnimation() {
        closeAnim.stop()
        entranceAnim.stop()
        closeProgress = 0.0
        if (root.animationsEnabled) {
            openProgress = 0.0
            entranceAnim.restart()
        } else {
            openProgress = 1.0
        }
    }

    function switchToPage(targetPage, originOrder) {
        pageHost.pendingOrderHint = originOrder !== undefined ? originOrder : -1
        if (searchField.text.length > 0) {
            searchField.text = ""
        }
        fullRep.currentPage = targetPage
        if (pageHost.shownIndex !== (fullRep.searching ? 7 : fullRep.currentPage)) {
            pageHost.goTo(fullRep.searching ? 7 : fullRep.currentPage, originOrder)
        }
    }

    Connections {
        target: root
        function onExpandedChanged() {
            if (root.expanded) {
                closeAnim.stop()
                entranceAnim.stop()
                root.closingLauncher = false
                closeProgress = 0.0
                if (root.animationsEnabled) {
                    openProgress = 0.0
                }
                fullRep.reset()
                pageHost.syncImmediate(fullRep.searching ? 7 : fullRep.currentPage)
                searchField.forceActiveFocus()
                if (root.animationsEnabled) {
                    entranceAnim.restart()
                } else {
                    openProgress = 1.0
                }
            } else {
                entranceAnim.stop()
                closeAnim.stop()
                root.closingLauncher = false
                fullRep.closeProgress = 0.0
                fullRep.openProgress = 1.0
            }
        }
    }

    Component.onCompleted: {
        root.fullRepInstance = fullRep
        if (root.expanded) {
            root.closingLauncher = false
            if (root.animationsEnabled) {
                openProgress = 0.0
            }
            fullRep.reset()
            pageHost.syncImmediate(fullRep.searching ? 7 : fullRep.currentPage)
            searchField.forceActiveFocus()
            if (root.animationsEnabled) {
                entranceAnim.restart()
            } else {
                openProgress = 1.0
            }
        }
    }

    Component.onDestruction: {
        if (root.fullRepInstance === fullRep) {
            root.fullRepInstance = null
        }
        root.closingLauncher = false
    }

    NumberAnimation {
        id: entranceAnim
        target: fullRep
        property: "openProgress"
        from: 0.0
        to: 1.0
        duration: root.animDuration
        easing.type: Easing.Linear
    }

    NumberAnimation {
        id: closeAnim
        target: fullRep
        property: "closeProgress"
        from: 0.0
        to: 1.0
        duration: root.animationsEnabled ? Math.max(120, Math.round(root.animDuration * 0.78)) : 0
        easing.type: Easing.Linear
        onFinished: {
            const cb = fullRep.closeCallback
            fullRep.closeCallback = null
            if (cb) cb()
            root.expanded = false
            root.closingLauncher = false
            fullRep.closeProgress = 0.0
            fullRep.openProgress = 1.0
        }
    }

    // ---- base surface & Future atmospheric backdrop ----
    Rectangle {
        id: surfaceRect
        anchors.fill: parent
        radius: fullRep.radius
        color: fullRep.surface
        border.width: 1
        border.color: root.shellBorderColor
        // Phase-1: scale up from top-left origin (avatar corner) + fade in
        opacity: fullRep.tShell * (1.0 - 0.9 * fullRep.cEase)
        transformOrigin: Item.TopLeft
        scale: fullRep.eff === 1 ? 1.0 : (0.72 + 0.28 * fullRep.tShell)

        // Subtle vertical specular glass depth wash
        Rectangle {
            visible: !root.isClassic
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, fullRep.radius - 1)
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.isDark
                        ? Qt.rgba(1, 1, 1, root.isSpatial ? 0.05 : 0.035)
                        : Qt.rgba(1, 1, 1, 0.28)
                }
                GradientStop {
                    position: 0.45
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: root.withAlpha(fullRep.accent, root.isHud ? 0.055 : (root.isCyber ? 0.04 : 0.025))
                }
            }
        }

        // Ambient radial aurora glow radiating gently from top-left avatar region
        Shape {
            visible: root.isSpatial || root.isHud
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            opacity: fullRep.tShell

            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: fullRep.ribbonSize * 0.9
                    centerY: fullRep.ribbonSize * 0.9
                    focalX: centerX
                    focalY: centerY
                    centerRadius: Math.min(surfaceRect.width, surfaceRect.height) * 0.62
                    GradientStop {
                        position: 0.0
                        color: root.withAlpha(fullRep.accent, root.isHud ? (fullRep.isDark ? 0.16 : 0.11) : (fullRep.isDark ? 0.12 : 0.08))
                    }
                    GradientStop {
                        position: 0.55
                        color: root.withAlpha(fullRep.accent, fullRep.isDark ? 0.035 : 0.02)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
                PathAngleArc {
                    centerX: fullRep.ribbonSize * 0.9
                    centerY: fullRep.ribbonSize * 0.9
                    radiusX: Math.min(surfaceRect.width, surfaceRect.height) * 0.62
                    radiusY: radiusX
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        // Ultra-faint clipped technical micro-grid for Cyber-Tech Neo-Minimal
        Canvas {
            id: cyberGrid
            visible: root.isCyber
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: if (visible) requestPaint()
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (width <= 0 || height <= 0) return

                const r = fullRep.radius
                ctx.save()
                ctx.beginPath()
                ctx.moveTo(r, 0)
                ctx.lineTo(width - r, 0)
                ctx.quadraticCurveTo(width, 0, width, r)
                ctx.lineTo(width, height - r)
                ctx.quadraticCurveTo(width, height, width - r, height)
                ctx.lineTo(r, height)
                ctx.quadraticCurveTo(0, height, 0, height - r)
                ctx.lineTo(0, r)
                ctx.quadraticCurveTo(0, 0, r, 0)
                ctx.closePath()
                ctx.clip()

                const c = fullRep.accent
                ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, fullRep.isDark ? 0.055 : 0.045)
                ctx.lineWidth = 1
                const step = 28
                ctx.beginPath()
                for (let gx = step; gx < width; gx += step) {
                    ctx.moveTo(gx + 0.5, 0)
                    ctx.lineTo(gx + 0.5, height)
                }
                for (let gy = step; gy < height; gy += step) {
                    ctx.moveTo(0, gy + 0.5)
                    ctx.lineTo(width, gy + 0.5)
                }
                ctx.stroke()
                ctx.restore()
            }
        }

        // Top specular rim hairline inside outer shell
        Rectangle {
            visible: !root.isClassic
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.leftMargin: Math.max(12, fullRep.radius)
            anchors.rightMargin: Math.max(12, fullRep.radius)
            height: 1
            color: root.specularColor
            opacity: root.isHud ? 0.72 : 0.55
        }

        // Precision corner brackets for HUD & Cyber-Tech modes
        Item {
            visible: root.isHud || root.isCyber
            anchors.fill: parent
            anchors.margins: 5
            opacity: root.isCyber ? 0.72 : 0.48

            // Top-right bracket
            Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 10; height: 1.5; color: fullRep.accent }
            Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: 1.5; height: 10; color: fullRep.accent }
            // Bottom-right bracket
            Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 10; height: 1.5; color: fullRep.accent }
            Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: 1.5; height: 10; color: fullRep.accent }
            // Bottom-left bracket
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 10; height: 1.5; color: fullRep.accent }
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: 1.5; height: 10; color: fullRep.accent }
        }
    }

    // Continuous L-shelf glass/tech background with analytic curve rendering,
    // concave inner fillet, gradient sheen, and unified perimeter border.
    Shape {
        id: lShelfShape
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: fullRep.tShell * (1.0 - 0.9 * fullRep.cEase)
        transformOrigin: Item.TopLeft
        scale: surfaceRect.scale

        readonly property real tx: topRibbon.x
        readonly property real ty: topRibbon.y
        readonly property real tw: topRibbon.width
        readonly property real th: topRibbon.height
        readonly property real lw: leftRibbon.width
        readonly property real totalH: topRibbon.height + leftRibbon.height
        readonly property real r: Math.max(0, Math.min(fullRep.radius, lw * 0.48, th * 0.48))
        readonly property real ir: (root.isCyber || r < 4)
            ? 0
            : Math.min(r * 0.72, Math.max(0, (tw - lw) * 0.45), Math.max(0, leftRibbon.height * 0.45))

        readonly property string shelfPath: {
            if (tw <= lw + 4 || th <= 4 || totalH <= th + 4) {
                return ""
            }
            const x0 = tx
            const y0 = ty
            const x1 = tx + tw
            const y1 = ty + th
            const xIn = tx + lw
            const y2 = ty + totalH
            const rad = r
            const inRad = ir

            if (root.isCyber && rad >= 2) {
                // Crisp architectural chamfered corners
                const c = Math.min(rad, 8)
                return "M " + (x0 + c) + " " + y0
                    + " L " + (x1 - c) + " " + y0
                    + " L " + x1 + " " + (y0 + c)
                    + " L " + x1 + " " + (y1 - c)
                    + " L " + (x1 - c) + " " + y1
                    + " L " + xIn + " " + y1
                    + " L " + xIn + " " + (y2 - c)
                    + " L " + (xIn - c) + " " + y2
                    + " L " + (x0 + c) + " " + y2
                    + " L " + x0 + " " + (y2 - c)
                    + " L " + x0 + " " + (y0 + c)
                    + " Z"
            }

            const arc = (rx, ry, sweep, ex, ey) =>
                " A " + rx + " " + ry + " 0 0 " + sweep + " " + ex + " " + ey

            let d = "M " + (x0 + rad) + " " + y0
            d += " L " + (x1 - rad) + " " + y0
            d += rad > 0.5 ? arc(rad, rad, 1, x1, y0 + rad) : (" L " + x1 + " " + y0)
            d += " L " + x1 + " " + (y1 - rad)
            d += rad > 0.5 ? arc(rad, rad, 1, x1 - rad, y1) : (" L " + x1 + " " + y1)
            d += " L " + (xIn + inRad) + " " + y1
            d += inRad > 0.5 ? arc(inRad, inRad, 0, xIn, y1 + inRad) : (" L " + xIn + " " + y1)
            d += " L " + xIn + " " + (y2 - rad)
            d += rad > 0.5 ? arc(rad, rad, 1, xIn - rad, y2) : (" L " + xIn + " " + y2)
            d += " L " + (x0 + rad) + " " + y2
            d += rad > 0.5 ? arc(rad, rad, 1, x0, y2 - rad) : (" L " + x0 + " " + y2)
            d += " L " + x0 + " " + (y0 + rad)
            d += rad > 0.5 ? arc(rad, rad, 1, x0 + rad, y0) : (" L " + x0 + " " + y0)
            return d + " Z"
        }

        ShapePath {
            strokeColor: fullRep.ribbonBorderColor
            strokeWidth: 1
            fillColor: "transparent"
            fillGradient: LinearGradient {
                x1: lShelfShape.tx
                y1: lShelfShape.ty
                x2: lShelfShape.tx + lShelfShape.tw * 0.45
                y2: lShelfShape.ty + lShelfShape.totalH * 0.65
                GradientStop {
                    position: 0.0
                    color: (fullRep.ribbonStyle === 2 || fullRep.ribbonStyle === 3 || root.isClassic)
                        ? fullRep.ribbonColor
                        : root.blendColors(
                            fullRep.ribbonColor,
                            fullRep.isDark ? Qt.rgba(1, 1, 1, fullRep.ribbonColor.a) : Qt.rgba(1, 1, 1, Math.min(1, fullRep.ribbonColor.a + 0.1)),
                            root.isHud ? 0.08 : 0.05
                        )
                }
                GradientStop {
                    position: 1.0
                    color: fullRep.ribbonColor
                }
            }
            PathSvg { path: lShelfShape.shelfPath }
        }
    }

    // ---- top ribbon: avatar + favourites carousel ----
    Item {
        id: topRibbon
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Kirigami.Units.smallSpacing * 2
        height: fullRep.ribbonSize
        clip: true
        // Phase-2: slide down from above (behind the avatar area); on close slide back up
        opacity: fullRep.tRibbons * (1.0 - 0.70 * fullRep.cEase)
        transform: Translate {
            y: fullRep.eff === 1 ? 0.0
                : (-topRibbon.height * (1.0 - fullRep.tRibbons)
                   - Kirigami.Units.gridUnit * 1.5 * fullRep.cEase)
        }

        RowLayout {
            anchors.fill: parent
            // clear the overhanging avatar, which sits outside this layout
            anchors.leftMargin: avatarCircle.x + avatarCircle.width
                + Kirigami.Units.smallSpacing - topRibbon.x
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // favourites carousel — drag tiles to reorder, or drop an app
            // from any grid here to favourite it at that spot
            Item {
                id: favCarouselClip
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: fullRep.openProgress >= 0.99 && fullRep.closeProgress <= 0.001

                // Subtle glowing drop cue when dragging an app into Favourites
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 3
                    anchors.bottomMargin: 3
                    radius: Math.max(6, Math.round(fullRep.radius * 0.55))
                    color: root.withAlpha(fullRep.accent, 0.10)
                    border.width: 1
                    border.color: root.withAlpha(fullRep.accent, 0.65)
                    visible: favDropArea.containsDrag
                }

                ListView {
                    id: favCarousel
                    anchors.fill: parent
                    orientation: ListView.Horizontal
                    spacing: Kirigami.Units.smallSpacing
                    model: rootModel.favoritesModel
                    // Ribbon itself carries the phase-2 slide; just handle opacity here
                    opacity: fullRep.tRibbons

                    move: Transition {
                        NumberAnimation { duration: root.animShort; properties: "x, y"; easing.type: Easing.OutQuad }
                    }
                    moveDisplaced: Transition {
                        NumberAnimation { duration: root.animShort; properties: "x, y"; easing.type: Easing.OutQuad }
                    }

                    DropArea {
                        id: favDropArea
                        anchors.fill: parent
                        onPositionChanged: drag => {
                            const src = drag.source
                            if (src && src.favoriteDrag && src.itemIndex >= 0) {
                                const idx = favCarousel.indexAt(
                                    favCarousel.contentX + drag.x, favCarousel.contentY + drag.y)
                                if (idx >= 0 && idx !== src.itemIndex) {
                                    rootModel.favoritesModel.moveRow(src.itemIndex, idx)
                                }
                            }
                        }
                        onDropped: drop => {
                            const src = drop.source
                            const fm = rootModel.favoritesModel
                            const favId = (src && (src.favoriteId || src.dragUrl)) ? (src.favoriteId || src.dragUrl.toString()) : null
                            if (favId && !src.favoriteDrag && !fm.isFavorite(favId)) {
                                const idx = favCarousel.indexAt(
                                    favCarousel.contentX + drop.x, favCarousel.contentY + drop.y)
                                fm.addFavorite(favId, idx)
                                drop.accept()
                            }
                        }
                    }

                    delegate: Item {
                        id: favDelegate
                        width: favCarousel.height
                        height: favCarousel.height

                        Accessible.role: Accessible.Button
                        Accessible.name: model.display ?? ""

                        // read by the DropAreas via drag.source
                        readonly property int itemIndex: index
                        readonly property var favoriteId: model.favoriteId ?? null
                        readonly property bool favoriteDrag: true

                        Drag.dragType: Drag.Automatic
                        Drag.mimeData: ({ "favoritedrag": "", "text/uri-list": [model.url] })

                        DragHandler {
                            target: null
                            onActiveChanged: {
                                if (active) {
                                    favDelegate.grabToImage(result => {
                                        favDelegate.Drag.imageSource = result.url
                                        favDelegate.Drag.active = true
                                    })
                                } else {
                                    favDelegate.Drag.active = false
                                }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - Kirigami.Units.smallSpacing
                            height: width
                            radius: root.isCyber ? Math.max(4, Math.round(fullRep.radius * 0.55)) : Math.max(6, Math.round(fullRep.radius * 0.52))
                            scale: favMouse.pressed ? 0.88 : ((favMouse.containsMouse && root.animEffect !== 1) ? 1.06 : 1.0)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: root.animFast
                                    easing.type: root.animEasingType
                                    easing.overshoot: root.animOvershoot
                                }
                            }
                            color: {
                                if (fullRep.ribbonStyle === 2) {
                                    return favMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : Qt.rgba(1, 1, 1, 0.18)
                                }
                                return favMouse.containsMouse
                                    ? root.effectiveTileHoverColor
                                    : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.07 : 0.04)
                            }
                            border.color: {
                                if (fullRep.ribbonStyle === 2) {
                                    return favMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.65) : "transparent"
                                }
                                return favMouse.containsMouse
                                    ? root.cardHoverBorderColor
                                    : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.10 : 0.07)
                            }
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: root.animFast } }
                            Behavior on border.color { ColorAnimation { duration: root.animFast } }

                            // Specular top sheen on hover
                            Rectangle {
                                visible: favMouse.containsMouse && !root.isClassic
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 1
                                anchors.leftMargin: Math.min(parent.radius, 8)
                                anchors.rightMargin: Math.min(parent.radius, 8)
                                height: 1
                                color: root.specularColor
                                opacity: 0.72
                            }

                            Kirigami.Icon {
                                anchors.centerIn: parent
                                width: parent.width * 0.65
                                height: width
                                source: model.decoration
                            }
                        }

                        QQC2.ToolTip.text: model.display
                        QQC2.ToolTip.visible: favMouse.containsMouse
                        QQC2.ToolTip.delay: 600

                        MouseArea {
                            id: favMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    favContextMenu.row = index
                                    favContextMenu.popup()
                                } else {
                                    favCarousel.model.trigger(index, "", null)
                                    fullRep.closeWithAnimation()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    LauncherMenu {
        id: favContextMenu
        property int row: -1
        LauncherMenuItem {
            text: i18n("Remove from favourites")
            icon.name: "bookmark-remove"
            onTriggered: rootModel.favoritesModel.removeFavorite(
                rootModel.favoritesModel.favoriteIds[favContextMenu.row])
        }
    }

    // ---- left ribbon: navigation ----
    Item {
        id: leftRibbon
        anchors.top: topRibbon.bottom
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: Kirigami.Units.smallSpacing * 2
        anchors.bottomMargin: Kirigami.Units.smallSpacing * 2
        anchors.topMargin: 0   // butt up against the top ribbon — unified in lShelfShape
        width: fullRep.ribbonSize
        clip: true
        // Phase-2: slide in from left; on close retreat leftward
        opacity: fullRep.tRibbons * (1.0 - 0.70 * fullRep.cEase)
        transform: Translate {
            x: fullRep.eff === 1 ? 0.0
                : (-leftRibbon.width * (1.0 - fullRep.tRibbons)
                   - Kirigami.Units.gridUnit * 1.2 * fullRep.cEase)
        }

        ColumnLayout {
            id: navColumn
            anchors.fill: parent
            // leave room where the oversized avatar overhangs into the ribbon
            anchors.topMargin: Math.max(Kirigami.Units.smallSpacing * 2,
                avatarCircle.y + avatarCircle.height - leftRibbon.y
                + Kirigami.Units.smallSpacing)
            anchors.bottomMargin: Kirigami.Units.smallSpacing * 2
            spacing: fullRep.navSpacing

            Repeater {
                model: fullRep.visibleNavCount
                NavButton {
                    id: navBtn
                    iconName: fullRep.navItems[index].icon
                    label: fullRep.navItems[index].label
                    active: fullRep.currentPage === fullRep.navItems[index].page && !fullRep.searching
                    opacity: fullRep.navMenuOpacity
                    scale: fullRep.navMenuScale
                    transform: Translate { y: fullRep.navItemSlideY(index) }
                    onClicked: fullRep.switchToPage(fullRep.navItems[index].page, index)
                }
            }

            // ⋯ holds whatever didn't fit; highlighted when the current page
            // is one of its hidden entries
            NavButton {
                id: moreNavBtn
                visible: fullRep.overflowNavItems.length > 0
                iconName: "overflow-menu-symbolic"
                label: i18n("More")
                active: !fullRep.searching
                    && fullRep.overflowNavItems.some(it => it.page === fullRep.currentPage)
                opacity: fullRep.navMenuOpacity
                scale: fullRep.navMenuScale
                transform: Translate { y: fullRep.navItemSlideY(fullRep.visibleNavCount) }
                onClicked: overflowMenu.popup()
            }

            Item { Layout.fillHeight: true }

            NavButton {
                iconName: "configure-symbolic"
                label: i18n("System Settings")
                opacity: fullRep.bottomNavOpacity
                onClicked: {
                    KCMUtils.KCMLauncher.openSystemSettings("")
                    fullRep.closeWithAnimation()
                }
            }
            NavButton {
                iconName: "system-shutdown-symbolic"
                label: i18n("Power")
                opacity: fullRep.bottomNavOpacity
                onClicked: powerMenu.popup()
            }
        }
    }

    // avatar circle -> user account settings. Lives outside the ribbon
    // layouts and overspills them, badge-style, in the top-left corner;
    // declared after both ribbons so it paints on top with a luminous halo.
    Item {
        id: avatarCircle
        z: 20
        x: Kirigami.Units.smallSpacing
        y: Kirigami.Units.smallSpacing
        width: fullRep.ribbonSize * 1.4
        height: width
        // Phase-1: avatar slides up from below and fades in; on close it recedes upward
        opacity: fullRep.tAvatar * (1.0 - 0.85 * fullRep.cEase)
        transform: Translate {
            y: fullRep.eff === 1 ? 0.0
                : (Kirigami.Units.gridUnit * 3.2 * (1.0 - fullRep.tAvatar)
                   - Kirigami.Units.gridUnit * 2.0 * fullRep.cEase)
        }

        Accessible.role: Accessible.Button
        Accessible.name: i18n("Account settings — %1", avatarCircle.userName)

        readonly property bool hasImage: avatarImg.status === Image.Ready
        readonly property string userName: kuser.item
            ? (kuser.item.fullName || kuser.item.loginName || "") : ""
        readonly property string loginHandle: kuser.item
            ? (kuser.item.loginName || kuser.item.fullName || "") : ""
        // letter-on-colour fallback in the same spirit as the users
        // KCM: colour picked from a palette by name hash
        readonly property var initialsPalette: [
            "#e93a9a", "#e93d58", "#e9643a", "#ef973c", "#f67400", "#3dd425",
            "#00d485", "#00d3b8", "#3daee9", "#b875dc", "#926ee4", "#5e45e6"]
        readonly property color initialsColor: {
            let h = 0
            for (let i = 0; i < userName.length; i++) {
                h += userName.charCodeAt(i)
            }
            return initialsPalette[h % initialsPalette.length]
        }

        // Ambient radial accent halo behind the avatar
        Shape {
            id: avatarHaloGlow
            visible: !root.isClassic
            anchors.centerIn: parent
            width: parent.width * 1.38
            height: width
            preferredRendererType: Shape.CurveRenderer
            opacity: avatarMouse.containsMouse ? 0.95 : 0.65
            Behavior on opacity { NumberAnimation { duration: root.animFast } }

            ShapePath {
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: avatarHaloGlow.width / 2
                    centerY: avatarHaloGlow.height / 2
                    focalX: centerX
                    focalY: centerY
                    centerRadius: avatarHaloGlow.width / 2
                    GradientStop {
                        position: 0.55
                        color: root.withAlpha(fullRep.accent, root.isHud ? 0.42 : 0.26)
                    }
                    GradientStop {
                        position: 1.0
                        color: "transparent"
                    }
                }
                PathAngleArc {
                    centerX: avatarHaloGlow.width / 2
                    centerY: avatarHaloGlow.height / 2
                    radiusX: avatarHaloGlow.width / 2
                    radiusY: avatarHaloGlow.width / 2
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        // disc drawn with the curve renderer: analytic edge antialiasing,
        // smooth at any size
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: "transparent"
                fillColor: avatarCircle.hasImage
                    ? Kirigami.Theme.backgroundColor : avatarCircle.initialsColor
                PathAngleArc {
                    centerX: avatarCircle.width / 2
                    centerY: avatarCircle.height / 2
                    radiusX: avatarCircle.width / 2
                    radiusY: avatarCircle.height / 2
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !avatarCircle.hasImage
            text: avatarCircle.userName.length > 0
                ? avatarCircle.userName.charAt(0).toUpperCase() : "?"
            color: "white"
            font.pixelSize: Math.round(avatarCircle.height * 0.5)
            font.bold: true
        }

        Image {
            id: avatarImg
            anchors.fill: parent
            source: kuser.item ? kuser.item.faceIconUrl : ""
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectCrop
            cache: false
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: avatarMask
            }
        }
        Item {
            id: avatarMask
            anchors.fill: parent
            layer.enabled: true
            visible: false
            // curve-rendered mask so the photo crop edge stays smooth too
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: "black"
                    PathAngleArc {
                        centerX: avatarMask.width / 2
                        centerY: avatarMask.height / 2
                        radiusX: avatarMask.width / 2
                        radiusY: avatarMask.height / 2
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }
        }

        // Theme-reactive orbital / specular halo ring around the avatar
        Shape {
            id: avatarHaloRing
            visible: !root.isClassic
            anchors.centerIn: parent
            width: parent.width + 6
            height: width
            preferredRendererType: Shape.CurveRenderer
            rotation: (root.isHud || root.isCyber) && avatarMouse.containsMouse ? 36 : 0
            Behavior on rotation { NumberAnimation { duration: root.animLong; easing.type: root.animEasingType } }

            // Continuous specular rim for Spatial Liquid Glass
            ShapePath {
                strokeColor: root.isSpatial
                    ? root.withAlpha(avatarMouse.containsMouse ? fullRep.accent : root.specularColor,
                                     avatarMouse.containsMouse ? 0.85 : 0.45)
                    : "transparent"
                strokeWidth: 1.5
                fillColor: "transparent"
                PathAngleArc {
                    centerX: avatarHaloRing.width / 2
                    centerY: avatarHaloRing.height / 2
                    radiusX: avatarHaloRing.width / 2 - 2
                    radiusY: avatarHaloRing.width / 2 - 2
                    startAngle: 0
                    sweepAngle: 360
                }
            }

            // Segmented orbital arcs for HUD & Cyber-Tech modes
            ShapePath {
                strokeColor: (root.isHud || root.isCyber)
                    ? root.withAlpha(fullRep.accent, avatarMouse.containsMouse ? 0.95 : 0.72)
                    : "transparent"
                strokeWidth: root.isCyber ? 1.8 : 1.6
                capStyle: root.isCyber ? ShapePath.FlatCap : ShapePath.RoundCap
                fillColor: "transparent"
                PathAngleArc {
                    centerX: avatarHaloRing.width / 2
                    centerY: avatarHaloRing.height / 2
                    radiusX: avatarHaloRing.width / 2 - 1.5
                    radiusY: avatarHaloRing.width / 2 - 1.5
                    startAngle: -35
                    sweepAngle: 125
                }
            }
            ShapePath {
                strokeColor: (root.isHud || root.isCyber)
                    ? root.withAlpha(fullRep.accent, avatarMouse.containsMouse ? 0.85 : 0.50)
                    : "transparent"
                strokeWidth: 1.4
                capStyle: root.isCyber ? ShapePath.FlatCap : ShapePath.RoundCap
                fillColor: "transparent"
                PathAngleArc {
                    centerX: avatarHaloRing.width / 2
                    centerY: avatarHaloRing.height / 2
                    radiusX: avatarHaloRing.width / 2 - 1.5
                    radiusY: avatarHaloRing.width / 2 - 1.5
                    startAngle: 145
                    sweepAngle: 125
                }
            }
        }

        // Subtle live session presence dot seated cleanly along the 45-degree rim
        Rectangle {
            visible: !root.isClassic
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: Math.round(parent.width * 0.07)
            anchors.bottomMargin: Math.round(parent.height * 0.07)
            width: 9
            height: 9
            radius: 4.5
            color: (root.isHud || root.isCyber) ? fullRep.accent : Qt.color("#34d399")
            border.width: 2
            border.color: Kirigami.Theme.backgroundColor
        }

        QQC2.ToolTip.text: i18n("Account settings — %1", avatarCircle.userName)
        QQC2.ToolTip.visible: avatarMouse.containsMouse
        MouseArea {
            id: avatarMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                KCMUtils.KCMLauncher.openSystemSettings("kcm_users")
                fullRep.closeWithAnimation()
            }
        }
    }

    LauncherMenu {
        id: overflowMenu
        Instantiator {
            model: fullRep.overflowNavItems
            delegate: LauncherMenuItem {
                text: modelData.label
                icon.name: modelData.icon
                onTriggered: fullRep.switchToPage(modelData.page, fullRep.visibleNavCount)
            }
            onObjectAdded: (index, object) => overflowMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => overflowMenu.removeItem(object)
        }
    }

    LauncherMenu {
        id: powerMenu
        Instantiator {
            model: systemModel
            delegate: LauncherMenuItem {
                text: model.display
                icon.name: model.decoration
                onTriggered: {
                    systemModel.trigger(index, "", null)
                    fullRep.closeWithAnimation()
                }
            }
            onObjectAdded: (index, object) => powerMenu.insertItem(index, object)
            onObjectRemoved: (index, object) => powerMenu.removeItem(object)
        }
    }

    // ---- content area (HUD status strip + animated page host) ----
    Item {
        id: contentArea
        clip: true
        anchors.top: topRibbon.bottom
        anchors.left: leftRibbon.right
        anchors.right: parent.right
        anchors.bottom: searchBarWrap.top
        anchors.margins: Kirigami.Units.smallSpacing * 2
        // Phase-3: pure fade in; on close fade out
        opacity: fullRep.tBody * (1.0 - 0.80 * fullRep.cEase)

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            // Compact Future HUD Status Strip (clears overhanging avatar circle)
            Rectangle {
                id: hudBar
                visible: root.showHudBar
                Layout.fillWidth: true
                Layout.leftMargin: Math.max(0, avatarCircle.x + avatarCircle.width + Kirigami.Units.smallSpacing - contentArea.x)
                Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.45)
                radius: root.pillRadius
                color: root.isClassic
                    ? "transparent"
                    : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.045 : 0.03)
                border.width: root.isClassic ? 0 : 1
                border.color: root.isCyber
                    ? root.withAlpha(fullRep.accent, 0.25)
                    : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.08 : 0.06)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 1.6
                    anchors.rightMargin: Kirigami.Units.smallSpacing * 1.2
                    spacing: Kirigami.Units.smallSpacing

                    // Breathing live status indicator
                    Rectangle {
                        Layout.preferredWidth: 6
                        Layout.preferredHeight: 6
                        radius: 3
                        color: fullRep.accent
                        opacity: 0.9
                        SequentialAnimation on opacity {
                            running: root.expanded && root.showHudBar && root.animationsEnabled
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.95; to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 0.35; to: 0.95; duration: 1400; easing.type: Easing.InOutSine }
                        }
                    }

                    StatusBadge {
                        visible: hudBar.width >= Kirigami.Units.gridUnit * 24
                            && (root.distroLabel.length > 0 || avatarCircle.loginHandle.length > 0)
                        text: root.distroLabel.length > 0
                            ? root.distroLabel
                            : ("@" + avatarCircle.loginHandle)
                        monospace: root.isCyber
                        textOpacity: 0.78
                    }

                    Item { Layout.fillWidth: true }

                    StatusBadge {
                        visible: fullRep.cpuPercent >= 0
                        text: i18n("CPU %1%", fullRep.cpuPercent)
                        accentTone: fullRep.cpuPercent >= 80
                        monospace: true
                    }

                    StatusBadge {
                        visible: fullRep.ramPercent >= 0
                        text: i18n("RAM %1%", fullRep.ramPercent)
                        accentTone: fullRep.ramPercent >= 85
                        monospace: true
                    }
                }
            }

            Item {
                id: pageHost
                Layout.fillWidth: true
                Layout.fillHeight: true

                readonly property int targetIndex: fullRep.searching ? 7 : fullRep.currentPage
                property int shownIndex: targetIndex
                property int outgoingIndex: -1
                property real slideDirY: 1.0
                property real progress: 1.0
                property int pendingOrderHint: -1

                function navOrderOf(pageIdx) {
                    if (pageIdx === 7) return 8
                    for (let i = 0; i < fullRep.navItems.length; i++) {
                        if (fullRep.navItems[i].page === pageIdx) return i
                    }
                    return 0
                }

                function syncImmediate(idx) {
                    pageSwitchAnim.stop()
                    outgoingIndex = -1
                    shownIndex = idx
                    progress = 1.0
                    pendingOrderHint = -1
                }

                function goTo(newIndex, originOrder) {
                    const orderHint = originOrder !== undefined ? originOrder
                                    : (pendingOrderHint >= 0 ? pendingOrderHint : navOrderOf(newIndex))
                    pendingOrderHint = -1
                    if (newIndex === shownIndex) {
                        return
                    }
                    const oldIdx = shownIndex
                    pageSwitchAnim.stop()
                    const oldOrd = navOrderOf(oldIdx)
                    slideDirY = orderHint >= oldOrd ? 1.0 : -1.0
                    outgoingIndex = oldIdx
                    shownIndex = newIndex

                    if (root.animationsEnabled && root.expanded && fullRep.openProgress >= 0.99) {
                        progress = 0.0
                        pageSwitchAnim.restart()
                    } else {
                        outgoingIndex = -1
                        progress = 1.0
                    }
                }

                onTargetIndexChanged: goTo(targetIndex)

                NumberAnimation {
                    id: pageSwitchAnim
                    target: pageHost
                    property: "progress"
                    from: 0.0
                    to: 1.0
                    duration: root.animDuration
                    easing.type: root.animEasingType
                    easing.overshoot: root.animOvershoot
                    onFinished: pageHost.outgoingIndex = -1
                }

                function pageVisible(idx) {
                    return shownIndex === idx || (pageSwitchAnim.running && outgoingIndex === idx)
                }
                function pageOpacity(idx) {
                    if (!pageSwitchAnim.running) return shownIndex === idx ? 1.0 : 0.0
                    if (shownIndex === idx) return Math.min(1.0, progress * 1.2)
                    if (outgoingIndex === idx) return Math.max(0.0, 1.0 - progress * 1.45)
                    return 0.0
                }
                function pageTx(idx) {
                    if (!pageSwitchAnim.running) return 0.0
                    const eff = root.animEffect
                    if (eff === 1 || eff === 2) return 0.0
                    const dist = (eff === 3 || eff === 4) ? (Kirigami.Units.gridUnit * 4.0) : (Kirigami.Units.gridUnit * 2.6)
                    if (shownIndex === idx) {
                        return -dist * (1.0 - progress)
                    }
                    if (outgoingIndex === idx) {
                        return dist * 0.55 * progress
                    }
                    return 0.0
                }
                function pageTy(idx) {
                    if (!pageSwitchAnim.running) return 0.0
                    const eff = root.animEffect
                    if (eff === 1 || eff === 2) return 0.0
                    const dist = eff === 4 ? (Kirigami.Units.gridUnit * 4.5) : (Kirigami.Units.gridUnit * 3.2)
                    if (shownIndex === idx) {
                        return slideDirY * dist * (1.0 - progress)
                    }
                    if (outgoingIndex === idx) {
                        return -slideDirY * dist * 0.65 * progress
                    }
                    return 0.0
                }
                function pageScale(idx) {
                    if (!pageSwitchAnim.running) return 1.0
                    const eff = root.animEffect
                    if (eff === 1) return 1.0
                    if (eff === 2) {
                        if (shownIndex === idx) return 0.86 + 0.14 * progress
                        if (outgoingIndex === idx) return 1.0 + 0.05 * progress
                    }
                    if (shownIndex === idx) return 0.94 + 0.06 * progress
                    if (outgoingIndex === idx) return 1.0 - 0.04 * progress
                    return 1.0
                }

                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(0)
                    opacity: pageHost.pageOpacity(0)
                    scale: pageHost.pageScale(0)
                    transform: Translate { x: pageHost.pageTx(0); y: pageHost.pageTy(0) }
                    AppsPage { id: appsPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(1)
                    opacity: pageHost.pageOpacity(1)
                    scale: pageHost.pageScale(1)
                    transform: Translate { x: pageHost.pageTx(1); y: pageHost.pageTy(1) }
                    DocsPage { id: docsPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(2)
                    opacity: pageHost.pageOpacity(2)
                    scale: pageHost.pageScale(2)
                    transform: Translate { x: pageHost.pageTx(2); y: pageHost.pageTy(2) }
                    FavoritesPage { id: favsPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(3)
                    opacity: pageHost.pageOpacity(3)
                    scale: pageHost.pageScale(3)
                    transform: Translate { x: pageHost.pageTx(3); y: pageHost.pageTy(3) }
                    QuickPage { id: quickPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(4)
                    opacity: pageHost.pageOpacity(4)
                    scale: pageHost.pageScale(4)
                    transform: Translate { x: pageHost.pageTx(4); y: pageHost.pageTy(4) }
                    PlacesPage { id: placesPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(5)
                    opacity: pageHost.pageOpacity(5)
                    scale: pageHost.pageScale(5)
                    transform: Translate { x: pageHost.pageTx(5); y: pageHost.pageTy(5) }
                    RecentAppsPage { id: recentAppsPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(6)
                    opacity: pageHost.pageOpacity(6)
                    scale: pageHost.pageScale(6)
                    transform: Translate { x: pageHost.pageTx(6); y: pageHost.pageTy(6) }
                    LinksPage { id: linksPage; anchors.fill: parent }
                }
                Item {
                    anchors.fill: parent
                    visible: pageHost.pageVisible(7)
                    opacity: pageHost.pageOpacity(7)
                    scale: pageHost.pageScale(7)
                    transform: Translate { x: pageHost.pageTx(7); y: pageHost.pageTy(7) }
                    SearchPage { id: searchPage; anchors.fill: parent }
                }
            }
        }
    }

    // ---- bottom search bar (ambient halo + capsule + shortcut hint + clear) ----
    Item {
        id: searchBarWrap
        anchors.left: leftRibbon.right
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Kirigami.Units.smallSpacing * 2
        height: Kirigami.Units.gridUnit * 2.35
        // Phase-2: slides up from the bottom edge; on close slides back down
        opacity: fullRep.tSearch * (1.0 - 0.75 * fullRep.cEase)
        transform: Translate {
            id: searchBarTranslate
            y: fullRep.eff === 1 ? 0.0
                : (Kirigami.Units.gridUnit * 3.5 * (1.0 - fullRep.tSearch)
                   + Kirigami.Units.gridUnit * 1.5 * fullRep.cEase)
        }

        // Ambient focus aura
        Rectangle {
            visible: !root.isClassic
            anchors.fill: searchBar
            anchors.margins: -3
            radius: root.isCyber ? (root.cardRadius + 3) : (height / 2)
            color: root.withAlpha(fullRep.accent, searchField.activeFocus ? 0.14 : 0.0)
            border.width: 1
            border.color: root.withAlpha(fullRep.accent, searchField.activeFocus ? 0.25 : 0.0)
            Behavior on color { ColorAnimation { duration: root.animFast } }
            Behavior on border.color { ColorAnimation { duration: root.animFast } }
        }

        Rectangle {
            id: searchBar
            anchors.fill: parent
            radius: root.isCyber ? root.cardRadius : height / 2
            color: fullRep.searchBarColor
            border.color: fullRep.searchBarBorderColor
            border.width: searchField.activeFocus ? 1.5 : 1
            Behavior on border.color { ColorAnimation { duration: root.animFast } }
            Behavior on color { ColorAnimation { duration: root.animFast } }

            // Specular top rim on the search capsule
            Rectangle {
                visible: !root.isClassic
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: 1
                anchors.leftMargin: Math.min(parent.radius, 18)
                anchors.rightMargin: Math.min(parent.radius, 18)
                height: 1
                color: root.specularColor
                opacity: searchField.activeFocus ? 0.72 : 0.40
                Behavior on opacity { NumberAnimation { duration: root.animFast } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.smallSpacing * 2.2
                anchors.rightMargin: Kirigami.Units.smallSpacing * 1.2
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "search-symbolic"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    isMask: true
                    color: searchField.activeFocus ? fullRep.accent : fullRep.textColor
                    opacity: searchField.activeFocus ? 1.0 : 0.65
                    scale: (searchField.activeFocus && root.animEffect !== 1) ? 1.10 : 1.0
                    Behavior on scale { NumberAnimation { duration: root.animFast; easing.type: root.animEasingType; easing.overshoot: root.animOvershoot } }
                    Behavior on color { ColorAnimation { duration: root.animFast } }
                    Behavior on opacity { NumberAnimation { duration: root.animFast } }
                }

                QQC2.TextField {
                    id: searchField
                    Layout.fillWidth: true
                    color: fullRep.textColor
                    placeholderTextColor: root.withAlpha(fullRep.textColor, 0.50)
                    placeholderText: i18n("Search apps, files, math, commands…")
                    background: null
                    onTextChanged: runnerModel.query = text
                    Keys.onEscapePressed: {
                        if (text.length > 0) { text = "" } else { fullRep.closeWithAnimation() }
                    }
                    Keys.onDownPressed: fullRep.focusContent()
                    Keys.onTabPressed: fullRep.focusContent()
                    Keys.onReturnPressed: if (fullRep.searching) searchPage.runFirst()
                }

                // Clear search button
                Item {
                    visible: fullRep.searching
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small + 6
                    Layout.preferredHeight: Layout.preferredWidth

                    Rectangle {
                        anchors.fill: parent
                        radius: root.isCyber ? 4 : width / 2
                        color: clearMouse.containsMouse
                            ? root.effectiveTileHoverColor
                            : root.withAlpha(fullRep.textColor, fullRep.isDark ? 0.08 : 0.05)
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.small * 0.85
                        height: width
                        source: "edit-clear-symbolic"
                        isMask: true
                        color: clearMouse.containsMouse ? fullRep.accent : fullRep.textColor
                    }
                    QQC2.ToolTip.text: i18n("Clear search (Esc)")
                    QQC2.ToolTip.visible: clearMouse.containsMouse
                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }

                // Subtle command-palette shortcut hint
                StatusBadge {
                    visible: searchBar.width >= Kirigami.Units.gridUnit * 16
                    text: fullRep.searching ? "↵" : "Tab"
                    accentTone: fullRep.searching
                    monospace: true
                    textOpacity: 0.72
                }

                // Search tricks button styled to match Future chrome
                Item {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small + 8
                    Layout.preferredHeight: Layout.preferredWidth

                    Rectangle {
                        anchors.fill: parent
                        radius: root.isCyber ? 4 : width / 2
                        color: tricksMouse.containsMouse ? root.effectiveTileHoverColor : "transparent"
                        border.width: tricksMouse.containsMouse ? 1 : 0
                        border.color: root.cardHoverBorderColor
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.small
                        height: width
                        source: "help-contextual-symbolic"
                        isMask: true
                        color: tricksMouse.containsMouse ? fullRep.accent : fullRep.textColor
                        opacity: tricksMouse.containsMouse ? 1.0 : 0.7
                    }
                    QQC2.ToolTip.text: i18n("Search tricks")
                    QQC2.ToolTip.visible: tricksMouse.containsMouse
                    MouseArea {
                        id: tricksMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: helpPopup.open()
                    }
                }
            }
        }
    }

    // ---- KRunner cheatsheet popup (styled glass card with interactive try-it chips) ----
    QQC2.Popup {
        id: helpPopup
        anchors.centerIn: parent
        width: Math.min(parent.width - Kirigami.Units.gridUnit * 2, Kirigami.Units.gridUnit * 22)
        height: Math.min(parent.height - Kirigami.Units.gridUnit * 3, Kirigami.Units.gridUnit * 26)
        modal: true
        padding: Kirigami.Units.largeSpacing

        background: Rectangle {
            radius: fullRep.radius
            color: root.blendColors(
                Kirigami.Theme.backgroundColor,
                fullRep.isDark ? Qt.color("#090d14") : Qt.color("#ffffff"),
                fullRep.isDark ? 0.30 : 0.20
            )
            opacity: 0.97
            border.width: 1
            border.color: root.withAlpha(fullRep.accent, 0.45)

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
                opacity: 0.65
            }
        }

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: root.animFast; easing.type: root.animEasingType; easing.overshoot: root.animOvershoot }
                NumberAnimation { property: "scale"; from: (!root.animationsEnabled || root.animEffect === 1) ? 1.0 : 0.86; to: 1.0; duration: root.animFast; easing.type: root.animEasingType; easing.overshoot: root.animOvershoot }
            }
        }
        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: root.animationsEnabled ? Math.max(60, Math.round(root.animFast * 0.75)) : 0; easing.type: Easing.InQuad }
                NumberAnimation { property: "scale"; from: 1.0; to: (!root.animationsEnabled || root.animEffect === 1) ? 1.0 : 0.88; duration: root.animationsEnabled ? Math.max(60, Math.round(root.animFast * 0.75)) : 0; easing.type: Easing.InQuad }
            }
        }

        contentItem: ColumnLayout {
            spacing: Kirigami.Units.smallSpacing * 1.4

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Kirigami.Icon {
                    source: "search-symbolic"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Layout.preferredWidth
                    isMask: true
                    color: fullRep.accent
                }
                Kirigami.Heading {
                    text: i18n("KRunner Command Bar")
                    level: 2
                    Layout.fillWidth: true
                }
                StatusBadge {
                    text: i18n("Click a chip to try")
                    accentTone: true
                }
            }

            // Interactive try-it example chips
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: ["=42*7", "34 C in F", "100 USD in EUR", "define serendipity", "$uname -r"]
                    delegate: Item {
                        required property string modelData
                        implicitWidth: chipBadge.implicitWidth
                        implicitHeight: chipBadge.implicitHeight

                        StatusBadge {
                            id: chipBadge
                            text: modelData
                            accentTone: chipMouse.containsMouse
                            monospace: true
                        }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                helpPopup.close()
                                searchField.text = modelData
                                searchField.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                QQC2.Label {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    textFormat: Text.MarkdownText
                    color: fullRep.textColor
                    text: i18n("The search bar is powered by KRunner — it does far more than apps:\n\n" +
                        "- **Math**: type `=42*7` or just `42*7`\n" +
                        "- **Units**: `34 C in F`, `100 USD in CAD`\n" +
                        "- **Files**: start typing any file name\n" +
                        "- **Spell check**: `spell recieve`\n" +
                        "- **Definitions**: `define serendipity`\n" +
                        "- **Open windows**: type part of a window title\n" +
                        "- **Web**: `gg:search terms` for Google, `dd:` for DuckDuckGo\n" +
                        "- **Shell**: prefix any command with `$`… or just type it\n" +
                        "- **Kill apps**: `kill firefox`\n" +
                        "- **Sessions**: `lock`, `sleep`, `restart`, `shut down`\n\n" +
                        "Manage which runners are active in System Settings → Search.")
                }
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignRight
                text: i18n("Close")
                onClicked: helpPopup.close()
            }
        }
    }
}
