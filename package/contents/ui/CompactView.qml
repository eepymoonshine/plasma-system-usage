import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compact

    readonly property bool showLabels: Plasmoid.configuration.showLabels !== false
    readonly property string fontFamily: Plasmoid.configuration.panelFontFamily || Kirigami.Theme.defaultFont.family
    readonly property real fontSize: Plasmoid.configuration.panelFontSize || 0   // 0 = automatic per style
    readonly property bool fontBold: Plasmoid.configuration.panelFontBold !== false

    // Horizontal padding: full gap on the left, tighter on the right
    readonly property real leftPad: Kirigami.Units.largeSpacing
    readonly property real rightPad: root.isVerticalLayout ? Kirigami.Units.largeSpacing : Kirigami.Units.smallSpacing

    Layout.minimumWidth: usageRow.implicitWidth + leftPad + rightPad
    Layout.minimumHeight: root.isVerticalLayout ? usageRow.implicitHeight + Kirigami.Units.largeSpacing * 2 : Kirigami.Units.iconSizes.medium
    Layout.preferredWidth: usageRow.implicitWidth + leftPad + rightPad
    Layout.preferredHeight: root.isVerticalLayout ? usageRow.implicitHeight + Kirigami.Units.largeSpacing * 2 : -1

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: function(mouse) {
            if (mouse.button === Qt.MiddleButton) root.openSystemMonitor()
            else root.expanded = !root.expanded
        }
    }

    GridLayout {
        id: usageRow
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: (compact.leftPad - compact.rightPad) / 2
        columns: root.isVerticalLayout ? 1 : -1
        rows: root.isVerticalLayout ? -1 : 1
        flow: root.isVerticalLayout ? GridLayout.TopToBottom : GridLayout.LeftToRight
        columnSpacing: Kirigami.Units.largeSpacing
        rowSpacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            visible: Plasmoid.configuration.showIcon === true
            source: "utilities-system-monitor"
            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
            Layout.alignment: Qt.AlignCenter
        }

        Repeater {
            model: root.panelMetrics

            delegate: GridLayout {
                id: metric
                required property var modelData
                required property int index

                readonly property color usageColor: root.getUsageColor(modelData.percent)

                Layout.alignment: Qt.AlignCenter
                columns: root.isVerticalLayout ? 1 : -1
                rows: root.isVerticalLayout ? -1 : 1
                flow: root.isVerticalLayout ? GridLayout.TopToBottom : GridLayout.LeftToRight
                columnSpacing: Kirigami.Units.smallSpacing
                rowSpacing: 0

                // Label (all styles)
                PlasmaComponents.Label {
                    visible: compact.showLabels
                    Layout.alignment: Qt.AlignCenter
                    text: metric.modelData.label
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize - 1
                    font.family: compact.fontFamily
                    font.letterSpacing: 0.8
                    font.bold: true
                    opacity: 0.55
                }

                // === TEXT STYLE ===
                Rectangle {
                    visible: root.panelStyle === "text"
                    Layout.preferredWidth: 10
                    Layout.preferredHeight: 10
                    Layout.alignment: Qt.AlignCenter
                    radius: 5
                    color: metric.usageColor
                }
                PlasmaComponents.Label {
                    visible: root.panelStyle === "text"
                    Layout.alignment: Qt.AlignCenter
                    // Fixed width so the panel doesn't jitter as digits change
                    Layout.preferredWidth: pctMetrics.advanceWidth
                    text: Math.round(metric.modelData.percent) + "%"
                    font: pctMetrics.font
                    TextMetrics {
                        id: pctMetrics
                        font.pointSize: compact.fontSize > 0 ? compact.fontSize : Kirigami.Theme.defaultFont.pointSize - 0.4
                        font.family: compact.fontFamily
                        font.bold: compact.fontBold
                        text: "100%"
                    }
                }

                // === BAR STYLE ===
                Item {
                    visible: root.panelStyle === "bar"
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: Math.min(compact.height - Kirigami.Units.smallSpacing * 2, 32)
                    Layout.minimumHeight: 20
                    Layout.alignment: Qt.AlignCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: Math.max((parent.height - 2) * Math.min(metric.modelData.percent / 100, 1), 1)
                            radius: 2
                            color: metric.usageColor
                            Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }

                    PlasmaComponents.Label {
                        anchors.centerIn: parent
                        text: Math.round(metric.modelData.percent)
                        font.pointSize: compact.fontSize > 0 ? compact.fontSize : 6.4
                        font.family: compact.fontFamily
                        font.bold: compact.fontBold
                        color: Kirigami.Theme.textColor
                        style: Text.Outline
                        styleColor: Kirigami.Theme.backgroundColor
                    }
                }

                // === RING STYLE ===
                UsageRing {
                    visible: root.panelStyle === "ring"
                    // Grow the ring if a large custom font wouldn't fit inside it
                    Layout.preferredWidth: Math.max(28, Math.ceil(ringMetrics.advanceWidth) + lineWidth * 2 + 4)
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignCenter
                    percent: metric.modelData.percent
                    ringColor: metric.usageColor
                    lineWidth: 3
                    fontScale: 0.27
                    fontPointSize: compact.fontSize
                    fontFamily: compact.fontFamily
                    fontBold: compact.fontBold

                    TextMetrics {
                        id: ringMetrics
                        font.pointSize: compact.fontSize > 0 ? compact.fontSize : 1
                        font.family: compact.fontFamily
                        font.bold: compact.fontBold
                        text: "100"
                    }
                }
            }
        }
    }
}
