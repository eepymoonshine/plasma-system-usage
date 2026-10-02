/*
    Based on UsageRing.qml from the Claude Usage plasmoid (izll, Hody).
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Shapes
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

// Progress ring with the percentage in the middle.
Item {
    id: ring

    property real percent: 0
    property real lineWidth: 4
    property color ringColor: Kirigami.Theme.positiveTextColor
    property color trackColor: Qt.alpha(Kirigami.Theme.textColor, 0.15)
    property bool showPercentSign: false
    property real fontScale: 0.3
    property string fontFamily: ""     // empty = theme font
    property real fontPointSize: 0     // 0 = scale with the ring
    property bool fontBold: true

    readonly property real arcRadius: Math.min(width, height) / 2 - lineWidth / 2
    readonly property real clamped: Math.max(0, Math.min(percent, 100))

    // Animate between readings
    property real animatedPercent: clamped
    Behavior on animatedPercent { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: ring.trackColor
            strokeWidth: ring.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: ring.ringColor
            strokeWidth: ring.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.arcRadius
                radiusY: ring.arcRadius
                startAngle: -90
                sweepAngle: 360 * ring.animatedPercent / 100
            }
        }
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        text: Math.round(ring.percent) + (ring.showPercentSign ? "%" : "")
        // Point sizes can be fractional (pt = px × 0.75)
        font.pointSize: ring.fontPointSize > 0 ? ring.fontPointSize : Math.max(5.25, ring.height * ring.fontScale * 0.75)
        font.family: ring.fontFamily || Kirigami.Theme.defaultFont.family
        font.bold: ring.fontBold
    }
}
