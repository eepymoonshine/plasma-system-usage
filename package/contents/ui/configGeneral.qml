/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_updateInterval: intervalSpin.value
    property string cfg_panelStyle
    property string cfg_panelLayout
    property alias cfg_showIcon: showIcon.checked
    property alias cfg_showLabels: showLabels.checked
    property alias cfg_showCpu: showCpu.checked
    property alias cfg_showRam: showRam.checked
    property alias cfg_showGpu: showGpu.checked
    property string cfg_panelFontFamily
    property real cfg_panelFontSize
    property alias cfg_panelFontBold: fontBold.checked
    property alias cfg_showCoreGraph: showCoreGraph.checked
    property alias cfg_warnThreshold: warnSpin.value
    property alias cfg_critThreshold: critSpin.value

    // Spin box with a unit, e.g. value 85 with scale 10 shows "8,5 pt"
    component UnitSpinBox: QQC2.SpinBox {
        property string suffix
        property int scale: 1
        property int decimals: 0

        // Same width so they line up, and padded since the style hugs the left border
        Layout.preferredWidth: Kirigami.Units.gridUnit * 6
        leftPadding: Kirigami.Units.mediumSpacing
        // Allow typing the unit and either "." or ","
        validator: RegularExpressionValidator { regularExpression: /\d+([.,]\d+)?\s*\S*/ }
        textFromValue: function(value, locale) {
            return (value / scale).toLocaleString(locale, 'f', decimals) + suffix
        }
        valueFromText: function(text, locale) {
            return Math.round(parseFloat(text.replace(",", ".")) * scale)
        }
    }

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: styleCombo
            Kirigami.FormData.label: i18n("Panel style:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Rings"), value: "ring" },
                { text: i18n("Bars"), value: "bar" },
                { text: i18n("Text"), value: "text" }
            ]
            // Set after load; a binding runs too early and gets stuck on the first item
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_panelStyle))
            onActivated: cfg_panelStyle = currentValue
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Layout:")
            textRole: "text"
            valueRole: "value"
            model: [
                { text: i18n("Horizontal"), value: "horizontal" },
                { text: i18n("Vertical"), value: "vertical" }
            ]
            // Same as above
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(cfg_panelLayout))
            onActivated: cfg_panelLayout = currentValue
        }

        QQC2.CheckBox { id: showLabels; text: i18n("Show labels (CPU / RAM / GPU)") }
        QQC2.CheckBox { id: showIcon; text: i18n("Show icon") }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Font:")
            QQC2.CheckBox {
                id: customFont
                text: i18n("Custom")
                checked: cfg_panelFontFamily !== ""
                onToggled: cfg_panelFontFamily = checked ? (fontCombo.editText || Kirigami.Theme.defaultFont.family) : ""
            }
            QQC2.ComboBox {
                id: fontCombo
                enabled: customFont.checked
                editable: true
                Layout.preferredWidth: Kirigami.Units.gridUnit * 14
                model: Qt.fontFamilies()
                // Ignore changes while loading, or the first font in the list overwrites the setting
                property bool loaded: false
                Component.onCompleted: {
                    var fam = cfg_panelFontFamily || Kirigami.Theme.defaultFont.family
                    var i = find(fam)
                    if (i >= 0) currentIndex = i
                    else editText = fam
                    loaded = true
                }
                // Saves both picked and typed names, no Enter needed
                onEditTextChanged: if (loaded && customFont.checked && editText !== "") cfg_panelFontFamily = editText
            }
        }

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.FormData.label: i18n("Number size:")
            QQC2.CheckBox {
                id: customSize
                text: i18n("Custom")
                checked: cfg_panelFontSize > 0
                onToggled: cfg_panelFontSize = checked ? sizeSpin.value / 10 : 0
            }
            UnitSpinBox {
                id: sizeSpin
                enabled: customSize.checked
                // Stored in tenths of a point for half-point steps
                suffix: " pt"; scale: 10; decimals: 1
                from: 40; to: 300; stepSize: 5
                value: cfg_panelFontSize > 0 ? Math.round(cfg_panelFontSize * 10) : 60
                onValueModified: cfg_panelFontSize = value / 10
            }
        }

        QQC2.CheckBox { id: fontBold; text: i18n("Bold numbers") }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showCpu; Kirigami.FormData.label: i18n("Show in panel:"); text: "CPU" }
        QQC2.CheckBox { id: showRam; text: "RAM" }
        QQC2.CheckBox { id: showGpu; text: "GPU" }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox { id: showCoreGraph; Kirigami.FormData.label: i18n("Popup:"); text: i18n("Show per-core CPU graph") }

        Item { Kirigami.FormData.isSection: true }

        UnitSpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Update interval:")
            suffix: " s"; scale: 1000; decimals: 2
            from: 250; to: 10000; stepSize: 250
        }

        // Keep yellow below red
        UnitSpinBox {
            id: warnSpin
            Kirigami.FormData.label: i18n("Yellow at:")
            suffix: "%"
            from: 1; to: critSpin.value - 1
        }
        UnitSpinBox {
            id: critSpin
            Kirigami.FormData.label: i18n("Red at:")
            suffix: "%"
            from: warnSpin.value + 1; to: 100
        }
    }
}
