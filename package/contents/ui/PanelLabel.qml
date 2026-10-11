/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import org.kde.plasma.components as PlasmaComponents

// Label whose digits and capitals are centered in the panel. Centering the line box
// instead leaves them about a pixel high: layout rounding and baseline snapping add up
PlasmaComponents.Label {
    id: label

    // The item to center in, normally the whole compact representation; null leaves it as is
    property Item panel: parent

    // Cleared so the theme font's style name (e.g. "Text") doesn't override the weight
    font.styleName: ""

    readonly property real topInPanel: {
        var y = 0
        for (var p = label; p && p !== panel; p = p.parent) y += p.y
        return y
    }

    transform: Translate {
        y: !label.panel ? 0 : Math.round((label.panel.height - glyphMetrics.tightBoundingRect.height) / 2)
            - (Math.round(label.topInPanel + label.baselineOffset) + glyphMetrics.tightBoundingRect.y)
    }

    TextMetrics { id: glyphMetrics; font: label.font; text: "0" }
}
