// SPDX-FileCopyrightText: 2026 Brock <dramascus@gmail.com>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick
import QtQuick.Shapes
import org.kde.kirigami as Kirigami

// The Useless Launcher "S" mark, drawn live so it can follow any colour
// (fixed blue, system accent, saturation-boosted accent…).
// solid: white S on a filled disc;
// ripples: S spilling over two concentric rings;
// futureCore: segmented orbital halo rings + luminous specular S core.
Item {
    id: mark

    property bool ripples: false
    property bool futureCore: false
    property bool opened: false
    property color color: "#fbbf24"
    property bool hovered: false
    // ripples / futureCore: render the S white/black (by theme) instead of coloured
    property bool contrastS: false
    // ripples / futureCore: soft radial glow behind the mark for dark panels
    property bool glow: true

    readonly property real s: Math.min(width, height)

    // ripples and futureCore get an automatic brightness lift so they don't sink into
    // dark panel backgrounds (solid mode has its disc for contrast)
    readonly property color ringColor: (ripples || futureCore)
        ? Qt.hsla(mark.color.hslHue,
                  Math.min(1, mark.color.hslSaturation * 1.15),
                  Math.min(0.75, mark.color.hslLightness * 1.35 + 0.08), 1)
        : mark.color
    readonly property color sColor: (!ripples && !futureCore)
        ? "white"
        : contrastS
            ? (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#ffffff" : "#232629")
            : ringColor
    readonly property color glowColor: Qt.hsla(ringColor.hslHue,
        ringColor.hslSaturation,
        Math.min(0.88, ringColor.hslLightness + 0.25), 1)

    // Brock's hand-drawn lightning S, cleaned up: straightened skeleton,
    // mitred corners, pen-style inner joins, tapered tips. Outline was
    // precomputed from the skeleton (see graphicDesign/Launcher) in a
    // 100x100 box.
    readonly property string glyph:
        "M 72.9,31.9 L 70.8,31.9 L 45.3,21.2 L 49.7,20.3 L 36.2,37.2 " +
        "L 35.0,31.5 L 71.6,50.7 L 47.4,72.8 L 33.1,82.5 L 31.2,83.1 " +
        "L 32.0,81.3 L 43.4,68.2 L 43.3,68.3 L 62.6,48.8 L 63.5,54.8 " +
        "L 27.5,36.0 L 46.2,13.4 L 71.8,30.1 Z"

    // soft glow so ripples & futureCore read sharply against dark panels
    Shape {
        visible: (mark.ripples || mark.futureCore) && mark.glow
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: mark.width / 2
                centerY: mark.height / 2
                focalX: centerX
                focalY: centerY
                centerRadius: mark.s / 2
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(mark.glowColor.r, mark.glowColor.g, mark.glowColor.b,
                                   mark.futureCore ? (mark.hovered ? 0.52 : 0.36) : 0.40)
                }
                GradientStop {
                    position: 0.62
                    color: Qt.rgba(mark.glowColor.r, mark.glowColor.g, mark.glowColor.b,
                                   mark.futureCore ? 0.16 : 0.14)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(mark.glowColor.r, mark.glowColor.g, mark.glowColor.b, 0.0)
                }
            }
            PathAngleArc {
                centerX: mark.width / 2
                centerY: mark.height / 2
                radiusX: mark.s / 2
                radiusY: mark.s / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Solid mode disc
    Rectangle {
        visible: !mark.ripples && !mark.futureCore
        anchors.centerIn: parent
        width: mark.s * 0.94
        height: width
        radius: width / 2
        color: mark.color
    }

    // Ripples mode concentric rings
    Repeater {
        model: mark.ripples ? 2 : 0
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: index === 0 ? mark.s * 0.70 : mark.s * 0.95
            height: width
            radius: width / 2
            color: "transparent"
            border.color: mark.ringColor
            border.width: Math.max(1.2, mark.s * (index === 0 ? 0.04 : 0.024))
            opacity: index === 0 ? 1.0 : 0.55
        }
    }

    // Future Core mode: crystalline core + segmented orbital rings
    Item {
        visible: mark.futureCore
        anchors.fill: parent

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // Smooth curve-rendered core disc + rim
            ShapePath {
                fillColor: Qt.rgba(mark.ringColor.r, mark.ringColor.g, mark.ringColor.b, mark.hovered ? 0.22 : 0.13)
                strokeColor: Qt.rgba(mark.glowColor.r, mark.glowColor.g, mark.glowColor.b, 0.48)
                strokeWidth: Math.max(1.0, mark.s * 0.024)
                PathAngleArc {
                    centerX: mark.width / 2
                    centerY: mark.height / 2
                    radiusX: mark.s * 0.37
                    radiusY: mark.s * 0.37
                    startAngle: 0
                    sweepAngle: 360
                }
            }
        }

        Shape {
            anchors.fill: parent
            transformOrigin: Item.Center
            preferredRendererType: Shape.CurveRenderer
            // Closed: left & right (0°); Hover (closed): 15°; Open: top & bottom (90°)
            rotation: mark.opened ? 90 : (mark.hovered ? 15 : 0)
            Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            // Right orbital arc (rotates to Bottom when opened)
            ShapePath {
                fillColor: "transparent"
                strokeColor: mark.ringColor
                strokeWidth: Math.max(1.4, mark.s * 0.040)
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: mark.width / 2
                    centerY: mark.height / 2
                    radiusX: mark.s * 0.45
                    radiusY: mark.s * 0.45
                    startAngle: -60
                    sweepAngle: 120
                }
            }
            // Left orbital arc (rotates to Top when opened)
            ShapePath {
                fillColor: "transparent"
                strokeColor: Qt.rgba(mark.glowColor.r, mark.glowColor.g, mark.glowColor.b, 0.85)
                strokeWidth: Math.max(1.4, mark.s * 0.040)
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: mark.width / 2
                    centerY: mark.height / 2
                    radiusX: mark.s * 0.45
                    radiusY: mark.s * 0.45
                    startAngle: 120
                    sweepAngle: 120
                }
            }
        }
    }

    // The lightning "S" glyph (solid & ripples)
    Shape {
        visible: !mark.futureCore
        anchors.centerIn: parent
        width: 100
        height: 100
        // in ripples mode the S overspills the inner ring on purpose
        scale: (mark.ripples ? mark.s * 0.88 : mark.s * 0.94) / 100
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: mark.sColor
            fillRule: ShapePath.WindingFill
            PathSvg { path: mark.glyph }
        }
    }

    // The lightning "S" glyph (Future Core specular gradient)
    Shape {
        visible: mark.futureCore
        anchors.centerIn: parent
        width: 100
        height: 100
        scale: (mark.s * 0.80) / 100
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.WindingFill
            fillGradient: LinearGradient {
                x1: 25; y1: 12
                x2: 75; y2: 86
                GradientStop {
                    position: 0.0
                    color: mark.contrastS ? mark.sColor : Qt.lighter(mark.glowColor, 1.35)
                }
                GradientStop {
                    position: 0.55
                    color: mark.sColor
                }
                GradientStop {
                    position: 1.0
                    color: mark.contrastS ? mark.sColor : mark.ringColor
                }
            }
            PathSvg { path: mark.glyph }
        }
    }
}
