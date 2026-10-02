/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: full
    clip: true

    readonly property color cardColor: Qt.alpha(Kirigami.Theme.textColor, 0.07)

    Layout.minimumWidth: Kirigami.Units.gridUnit * 19
    Layout.preferredWidth: Kirigami.Units.gridUnit * 21
    Layout.minimumHeight: mainColumn.implicitHeight + Kirigami.Units.smallSpacing * 2
    Layout.preferredHeight: mainColumn.implicitHeight + Kirigami.Units.smallSpacing * 2

    // Building blocks

    component SectionTitle: PlasmaComponents.Label {
        font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
        font.bold: true
        opacity: 0.55
    }

    component Card: Rectangle {
        default property alias content: inner.data
        Layout.fillWidth: true
        radius: Kirigami.Units.cornerRadius
        color: full.cardColor
        implicitHeight: inner.implicitHeight + Kirigami.Units.mediumSpacing * 2

        ColumnLayout {
            id: inner
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing
        }
    }

    component RingCard: Rectangle {
        id: ringCard
        property string title
        property string subtitle
        property real percent
        property color accent

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: 1   // equal thirds
        radius: Kirigami.Units.cornerRadius
        color: full.cardColor
        implicitHeight: ringCol.implicitHeight + Kirigami.Units.mediumSpacing * 2

        ColumnLayout {
            id: ringCol
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing

            UsageRing {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 56; Layout.preferredHeight: 56
                percent: ringCard.percent
                ringColor: root.getUsageColor(ringCard.percent)
                lineWidth: 5; showPercentSign: true; fontScale: 0.22
            }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Kirigami.Units.smallSpacing
                Rectangle { width: 6; height: 6; radius: 3; color: ringCard.accent }
                PlasmaComponents.Label {
                    text: ringCard.title
                    font.bold: true; font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                }
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                text: ringCard.subtitle
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.65; elide: Text.ElideRight
            }
        }
    }

    component DetailRow: RowLayout {
        id: detailRow
        property string label
        property string value      // "" when there's no reading
        property string fallback   // shown when the value drops back to ""

        // Once shown, stay shown. Some sensors flicker to 0, which would resize the popup
        property bool seen: false
        onValueChanged: if (value !== "") seen = true
        Component.onCompleted: if (value !== "") seen = true

        visible: seen
        Layout.fillWidth: true
        PlasmaComponents.Label { text: detailRow.label; opacity: 0.65 }
        Item { Layout.fillWidth: true }
        PlasmaComponents.Label {
            text: detailRow.value !== "" ? detailRow.value : detailRow.fallback
            font.features: ({ "tnum": 1 })
        }
    }

    // Layout

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.bottomMargin: Kirigami.Units.smallSpacing
        anchors.leftMargin: Kirigami.Units.mediumSpacing
        anchors.rightMargin: Kirigami.Units.mediumSpacing
        spacing: Kirigami.Units.smallSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "utilities-system-monitor"
                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            }
            PlasmaComponents.Label {
                text: i18n("System Usage")
                font.bold: true
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.25
            }
            Item { Layout.fillWidth: true }

            Rectangle {
                visible: root.ready(cpuCores)
                Layout.preferredWidth: coresLabel.implicitWidth + Kirigami.Units.largeSpacing
                Layout.preferredHeight: coresLabel.implicitHeight + Kirigami.Units.smallSpacing
                radius: height / 2
                color: Qt.alpha(root.cpuAccent, 0.18)

                PlasmaComponents.Label {
                    id: coresLabel
                    anchors.centerIn: parent
                    text: i18n("%1 threads", Math.round(root.num(cpuCores)))
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.bold: true; color: root.cpuAccent
                }
            }
        }

        // Rings
        RowLayout {
            Layout.fillWidth: true
            // Don't stretch into spare popup height, or the cards resize when rows appear below
            Layout.fillHeight: false
            spacing: Kirigami.Units.mediumSpacing

            RingCard {
                title: "CPU"
                subtitle: root.fmt(cpuFreq)
                percent: root.cpuPercent
                accent: root.cpuAccent
            }
            RingCard {
                title: i18n("Memory")
                subtitle: root.ready(ramUsed) && root.ready(ramTotal)
                    ? root.fmt(ramUsed).replace(/\s*\S+$/, "") + " / " + root.fmt(ramTotal)
                    : ""
                percent: root.ramUsagePercent
                accent: root.ramAccent
            }
            RingCard {
                visible: root.hasGpu
                title: "GPU"
                subtitle: root.num(vramTotal) > 0
                    ? root.fmt(vramUsed).replace(/\s*\S+$/, "") + " / " + root.fmt(vramTotal)
                    : root.fmt(gpuTemp)
                percent: root.gpuPercent
                accent: root.gpuAccent
            }
        }

        // Trend
        Card {
            RowLayout {
                Layout.fillWidth: true
                SectionTitle { text: i18n("Last %1 seconds", Math.round(root.historyLength * root.updateInterval / 1000)) }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: [
                        { label: "CPU", color: root.cpuAccent, show: true },
                        { label: "RAM", color: root.ramAccent, show: true },
                        { label: "GPU", color: root.gpuAccent, show: root.hasGpu }
                    ]
                    delegate: RowLayout {
                        required property var modelData
                        visible: modelData.show
                        spacing: Kirigami.Units.smallSpacing / 2
                        Rectangle { width: 6; height: 6; radius: 3; color: modelData.color }
                        PlasmaComponents.Label {
                            text: modelData.label
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            opacity: 0.65
                            rightPadding: Kirigami.Units.smallSpacing
                        }
                    }
                }
            }
            TrendChart {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                capacity: root.historyLength
                series: {
                    var s = [{ values: root.ramHistory, color: root.ramAccent },
                             { values: root.cpuHistory, color: root.cpuAccent }]
                    if (root.hasGpu) s.push({ values: root.gpuHistory, color: root.gpuAccent })
                    return s
                }
            }
        }

        // Per-core usage
        Card {
            id: coresCard
            visible: root.showCoreGraph && root.coreUsages.length > 0
            property int hoveredCore: -1
            readonly property real maxCore: Math.max.apply(null, root.coreUsages.concat([0]))

            RowLayout {
                Layout.fillWidth: true
                SectionTitle { text: i18n("Cores") }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    text: coresCard.hoveredCore >= 0
                        ? i18n("Core %1: %2%", coresCard.hoveredCore, Math.round(root.coreUsages[coresCard.hoveredCore] || 0))
                        : i18n("busiest %1%", Math.round(coresCard.maxCore))
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.features: ({ "tnum": 1 })
                    opacity: 0.55
                }
            }

            Row {
                id: coreBars
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.5
                spacing: root.coreUsages.length > 32 ? 1 : 2
                readonly property real barWidth: (width - spacing * (root.coreUsages.length - 1)) / Math.max(root.coreUsages.length, 1)

                Repeater {
                    // Using the count as model keeps the bars around so they animate
                    model: root.coreUsages.length
                    delegate: Item {
                        id: coreBar
                        required property int index
                        readonly property real percent: root.coreUsages[index] || 0
                        width: coreBars.barWidth
                        height: coreBars.height

                        Rectangle {
                            anchors.fill: parent
                            radius: Math.min(2, width / 2)
                            color: Qt.alpha(Kirigami.Theme.textColor, coreMouse.containsMouse ? 0.2 : 0.1)
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: Math.max(parent.height * Math.min(coreBar.percent, 100) / 100, 1)
                            radius: Math.min(2, width / 2)
                            color: root.getUsageColor(coreBar.percent)
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                        MouseArea {
                            id: coreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: {
                                if (containsMouse) coresCard.hoveredCore = coreBar.index
                                else if (coresCard.hoveredCore === coreBar.index) coresCard.hoveredCore = -1
                            }
                        }
                    }
                }
            }
        }

        // Processor
        Card {
            RowLayout {
                Layout.fillWidth: true
                SectionTitle { text: i18n("Processor") }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    text: root.cpuModel
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.55
                    elide: Text.ElideRight; Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                }
            }
            DetailRow { label: i18n("Temperature"); value: root.num(cpuTemp) > 0 ? root.fmt(cpuTemp) : "" }
            DetailRow { label: i18n("Clock"); value: root.fmt(cpuFreq) }
        }

        // Memory
        Card {
            SectionTitle { text: i18n("Memory") }
            DetailRow { label: i18n("Used"); value: root.ready(ramUsed) ? root.fmt(ramUsed) + " / " + root.fmt(ramTotal) : "" }
            DetailRow { label: i18n("Cache"); value: root.fmt(ramCache) }
            DetailRow { label: i18n("Swap"); value: root.ready(swapPercent) ? Math.round(root.num(swapPercent)) + "%" : "" }
        }

        // Graphics
        Card {
            visible: root.hasGpu
            RowLayout {
                Layout.fillWidth: true
                SectionTitle { text: i18n("Graphics") }
                Item { Layout.fillWidth: true }
                PlasmaComponents.Label {
                    text: root.gpuModel
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.55
                    elide: Text.ElideRight; Layout.maximumWidth: Kirigami.Units.gridUnit * 12
                }
            }
            DetailRow { label: i18n("Temperature"); value: root.num(gpuTemp) > 0 ? root.fmt(gpuTemp) : "" }
            // Always shown, since the clock reads 0 a lot when idle
            DetailRow { label: i18n("Clock"); value: !root.ready(gpuClock) ? "" : root.num(gpuClock) > 0 ? root.fmt(gpuClock) : i18n("Idle") }
            DetailRow { label: i18n("Power"); value: root.num(gpuPower) > 0 ? root.fmt(gpuPower) : ""; fallback: "0 W" }

            // VRAM bar
            RowLayout {
                visible: root.num(vramTotal) > 0
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label { text: "VRAM"; opacity: 0.65; Layout.preferredWidth: Kirigami.Units.gridUnit * 3.5 }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.15)
                    Rectangle {
                        width: parent.width * Math.min(root.vramPercent / 100, 1)
                        height: parent.height
                        radius: 3
                        color: root.getUsageColor(root.vramPercent)
                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                    }
                }
                PlasmaComponents.Label {
                    text: Math.round(root.vramPercent) + "%"
                    font.bold: true
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                    horizontalAlignment: Text.AlignRight
                }
            }
            PlasmaComponents.Label {
                visible: root.num(vramTotal) > 0
                Layout.alignment: Qt.AlignRight
                text: root.fmt(vramUsed) + " / " + root.fmt(vramTotal)
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize; opacity: 0.55
            }
        }

        // Footer
        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                // "1 s", "1,5 s", "1,25 s", in the user's locale
                readonly property int decimals: root.updateInterval % 1000 === 0 ? 0 : root.updateInterval % 100 === 0 ? 1 : 2
                text: i18n("Updating every %1 s", (root.updateInterval / 1000).toLocaleString(Qt.locale(), 'f', decimals))
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                opacity: 0.65
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents.ToolButton {
                icon.name: "utilities-system-monitor"
                text: i18n("System Monitor")
                onClicked: root.openSystemMonitor()
            }
        }

        Item { Layout.fillHeight: true }
    }
}
