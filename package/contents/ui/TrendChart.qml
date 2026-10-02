/*
    Based on TrendChart.qml from the Claude Usage plasmoid (Hody).
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

// Multi-series sparkline (line + soft area fill), 0..100 percent scale.
// series: array of {values: [percent, ...], color: color}
Canvas {
    id: chart

    property var series: []
    property int capacity: 60

    onSeriesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()

        var pad = 2
        var w = width - 2 * pad
        var h = height - 2 * pad

        // Right-align so the newest sample is always at the right edge
        function px(offset, i) { return pad + w * (offset + i) / (capacity - 1) }
        function py(v) { return pad + h - h * Math.max(0, Math.min(v, 100)) / 100 }

        // Faint 50% gridline
        ctx.strokeStyle = Qt.alpha(Kirigami.Theme.textColor, 0.08)
        ctx.lineWidth = 1
        ctx.beginPath()
        ctx.moveTo(pad, Math.round(pad + h / 2) + 0.5)
        ctx.lineTo(width - pad, Math.round(pad + h / 2) + 0.5)
        ctx.stroke()

        for (var s = 0; s < series.length; s++) {
            var vals = series[s].values
            if (!vals || vals.length < 2) continue

            var offset = capacity - vals.length

            ctx.beginPath()
            ctx.moveTo(px(offset, 0), height)
            for (var i = 0; i < vals.length; i++) ctx.lineTo(px(offset, i), py(vals[i]))
            ctx.lineTo(px(offset, vals.length - 1), height)
            ctx.closePath()
            ctx.fillStyle = Qt.alpha(series[s].color, 0.12)
            ctx.fill()

            ctx.beginPath()
            ctx.moveTo(px(offset, 0), py(vals[0]))
            for (var j = 1; j < vals.length; j++) ctx.lineTo(px(offset, j), py(vals[j]))
            ctx.strokeStyle = series[s].color
            ctx.lineWidth = 2
            ctx.lineJoin = "round"
            ctx.stroke()
        }
    }
}
