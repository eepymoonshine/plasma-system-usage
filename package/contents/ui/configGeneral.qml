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
            currentIndex: Math.max(0, indexOfValue(cfg_panelStyle))
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
            currentIndex: Math.max(0, indexOfValue(cfg_panelLayout))
            onActivated: cfg_panelLayout = currentValue
        }

        QQC2.CheckBox { id: showLabels; text: i18n("Show labels (CPU / RAM / GPU)") }
        QQC2.CheckBox { id: showIcon; text: i18n("Show icon") }

        Item { Kirigami.FormData.isSection: true }

        RowLayout {
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
                Component.onCompleted: {
                    var fam = cfg_panelFontFamily || Kirigami.Theme.defaultFont.family
                    var i = find(fam)
                    if (i >= 0) currentIndex = i
                    else editText = fam
                }
                onActivated: cfg_panelFontFamily = currentText
                onAccepted: cfg_panelFontFamily = editText
            }
        }

        RowLayout {
            Kirigami.FormData.label: i18n("Number size:")
            QQC2.CheckBox {
                id: customSize
                text: i18n("Custom")
                checked: cfg_panelFontSize > 0
                onToggled: cfg_panelFontSize = checked ? sizeSpin.value / 10 : 0
            }
            QQC2.SpinBox {
                id: sizeSpin
                enabled: customSize.checked
                // Stored in tenths of a point so half-point steps are possible
                from: 40; to: 300; stepSize: 5
                value: cfg_panelFontSize > 0 ? Math.round(cfg_panelFontSize * 10) : 60
                textFromValue: function(v) { return (v / 10).toLocaleString(Qt.locale(), 'f', 1) + " pt" }
                valueFromText: function(t) { return Math.round(Number.fromLocaleString(Qt.locale(), t.replace(/\s*pt$/, "")) * 10) }
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

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Update interval:")
            from: 250; to: 10000; stepSize: 250
            textFromValue: function(v) { return (v / 1000).toLocaleString(Qt.locale(), 'f', 2) + " s" }
            valueFromText: function(t) { return Math.round(Number.fromLocaleString(Qt.locale(), t.replace(/\s*s$/, "")) * 1000) }
        }

        QQC2.SpinBox {
            id: warnSpin
            Kirigami.FormData.label: i18n("Yellow at:")
            from: 1; to: 99
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) }
        }
        QQC2.SpinBox {
            id: critSpin
            Kirigami.FormData.label: i18n("Red at:")
            from: 2; to: 100
            textFromValue: function(v) { return v + "%" }
            valueFromText: function(t) { return parseInt(t) }
        }
    }
}
