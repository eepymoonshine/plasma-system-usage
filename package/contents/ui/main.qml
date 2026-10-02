/*
    SPDX-License-Identifier: GPL-3.0-or-later
*/

import QtQuick
import QtQml
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    readonly property int updateInterval: Math.max(Plasmoid.configuration.updateInterval || 1000, 250)
    readonly property int historyLength: 60

    // ===== Sensors (served by the ksystemstats daemon) =====

    Sensors.Sensor { id: cpuUsage;   sensorId: "cpu/all/usage";                 updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: cpuFreq;    sensorId: "cpu/all/averageFrequency";      updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: cpuTemp;    sensorId: "cpu/all/maximumTemperature";    updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: cpuCores;   sensorId: "cpu/all/coreCount" }

    Sensors.Sensor { id: ramPercent; sensorId: "memory/physical/usedPercent";   updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: ramUsed;    sensorId: "memory/physical/used";          updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: ramTotal;   sensorId: "memory/physical/total" }
    Sensors.Sensor { id: ramCache;   sensorId: "memory/physical/cache";         updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: swapPercent; sensorId: "memory/swap/usedPercent";      updateRateLimit: root.updateInterval }

    Sensors.Sensor { id: gpuUsage;   sensorId: "gpu/all/usage";                 updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: gpuName;    sensorId: "gpu/gpu0/name" }
    Sensors.Sensor { id: gpuTemp;    sensorId: "gpu/gpu0/temperature";          updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: gpuPower;   sensorId: "gpu/gpu0/power";                updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: gpuClock;   sensorId: "gpu/gpu0/coreFrequency";        updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: vramUsed;   sensorId: "gpu/all/usedVram";              updateRateLimit: root.updateInterval }
    Sensors.Sensor { id: vramTotal;  sensorId: "gpu/all/totalVram" }

    // One usage sensor per logical CPU (cpu/cpu0 … cpu/cpuN-1), only while the core graph is on
    readonly property bool showCoreGraph: Plasmoid.configuration.showCoreGraph !== false
    Instantiator {
        id: coreSensors
        model: root.showCoreGraph ? Math.round(root.num(cpuCores)) : 0
        delegate: Sensors.Sensor {
            required property int index
            sensorId: "cpu/cpu" + index + "/usage"
            updateRateLimit: root.updateInterval
        }
    }

    // ===== Derived values =====

    function num(sensor) {
        var v = Number(sensor.value)
        return isFinite(v) ? v : 0
    }
    function ready(sensor) { return sensor.status === Sensors.Sensor.Ready }
    // formattedValue looks like "500\u202FM\u200BHz". Many fonts lack the narrow no-break space
    // (U+202F), so it renders through a taller fallback font and rows jump in height as values
    // flip. Use a plain no-break space instead and drop the zero-width space.
    function fmt(sensor) {
        return ready(sensor) ? sensor.formattedValue.replace(/\u202F/g, "\u00A0").replace(/\u200B/g, "") : ""
    }

    readonly property real cpuPercent: num(cpuUsage)
    readonly property real ramUsagePercent: num(ramPercent)
    readonly property real gpuPercent: num(gpuUsage)
    readonly property real vramPercent: num(vramTotal) > 0 ? num(vramUsed) / num(vramTotal) * 100 : 0
    readonly property bool hasGpu: ready(gpuUsage)

    // ksystemstats has no CPU model sensor, so read it once from /proc/cpuinfo
    property string cpuModel: ""
    Plasma5Support.DataSource {
        engine: "executable"
        connectedSources: ["grep -m1 'model name' /proc/cpuinfo"]
        onNewData: function(sourceName, data) {
            root.cpuModel = root.cleanCpuName((data["stdout"] || "").replace(/^[^:]*:/, ""))
            disconnectSource(sourceName)
        }
    }
    readonly property string gpuModel: cleanGpuName(fmt(gpuName))

    function cleanCpuName(n) {
        return n.replace(/\((R|TM)\)/gi, "").replace(/ CPU/, "").replace(/ \d+-Core Processor/, "")
                .replace(/ Processor/, "").replace(/\s+@.*$/, "").replace(/\s+/g, " ").trim()
    }
    function cleanGpuName(n) {
        // "Navi 22 [Radeon RX 6700/6700 XT/...]" -> "Radeon RX 6700"
        var m = n.match(/\[([^\]]+)\]/)
        var s = m ? m[1] : n
        return s.split("/")[0].trim()
    }

    // ===== Rolling history for the trend chart =====

    property var cpuHistory: []
    property var ramHistory: []
    property var gpuHistory: []
    property var coreUsages: []   // latest percent per logical CPU

    function pushSample(list, value) {
        var next = list.slice(Math.max(0, list.length - root.historyLength + 1))
        next.push(value)
        return next
    }

    Timer {
        interval: root.updateInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            // Skip sensors that haven't delivered a first value yet, so charts don't start with a fake 0
            if (root.ready(cpuUsage)) root.cpuHistory = root.pushSample(root.cpuHistory, root.cpuPercent)
            if (root.ready(ramPercent)) root.ramHistory = root.pushSample(root.ramHistory, root.ramUsagePercent)
            if (root.hasGpu) root.gpuHistory = root.pushSample(root.gpuHistory, root.gpuPercent)

            var cores = []
            for (var i = 0; i < coreSensors.count; i++) {
                var sensor = coreSensors.objectAt(i)
                cores.push(sensor ? root.num(sensor) : 0)
            }
            root.coreUsages = cores
        }
    }

    // ===== Styling helpers =====

    readonly property color cpuAccent: "#D97757"
    readonly property color ramAccent: "#6A9BCC"
    readonly property color gpuAccent: "#9C87F5"

    function getUsageColor(percent) {
        var warn = Plasmoid.configuration.warnThreshold || 50
        var crit = Plasmoid.configuration.critThreshold || 80
        if (percent < warn) return Kirigami.Theme.positiveTextColor
        if (percent < crit) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.negativeTextColor
    }

    readonly property bool isVerticalLayout: Plasmoid.configuration.panelLayout === "vertical"
    readonly property string panelStyle: Plasmoid.configuration.panelStyle || "ring"

    // Metrics shown in the panel, in order
    readonly property var panelMetrics: {
        var list = []
        if (Plasmoid.configuration.showCpu !== false)
            list.push({ label: "CPU", percent: root.cpuPercent })
        if (Plasmoid.configuration.showRam !== false)
            list.push({ label: "RAM", percent: root.ramUsagePercent })
        if (Plasmoid.configuration.showGpu !== false && root.hasGpu)
            list.push({ label: "GPU", percent: root.gpuPercent })
        return list
    }

    Plasma5Support.DataSource {
        id: launcher
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) { disconnectSource(sourceName) }
    }

    function openSystemMonitor() {
        launcher.connectSource("kstart plasma-systemmonitor")
        root.expanded = false
    }

    compactRepresentation: CompactView {}
    fullRepresentation: FullView {}

    Plasmoid.icon: "utilities-system-monitor"
    toolTipMainText: i18n("System Usage")
    toolTipSubText: {
        var parts = ["CPU: " + Math.round(root.cpuPercent) + "%",
                     "RAM: " + Math.round(root.ramUsagePercent) + "%"]
        if (root.hasGpu) parts.push("GPU: " + Math.round(root.gpuPercent) + "%")
        return parts.join(" | ")
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Open System Monitor")
            icon.name: "utilities-system-monitor"
            onTriggered: root.openSystemMonitor()
        }
    ]
}
