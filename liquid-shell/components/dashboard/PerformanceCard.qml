import QtQuick
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    property real cpuUsage: 0
    property real ramUsage: 0
    property bool cpuReady: false
    property bool ramReady: false
    property real previousTotal: -1
    property real previousIdle: -1

    function updateStats(output) {
        const cpuLine = output.match(/^cpu\s+([^\n]+)/m)
        if (cpuLine) {
            const values = cpuLine[1].trim().split(/\s+/).map(Number)
            const total = values.reduce((sum, value) => sum + value, 0)
            const idle = (values[3] || 0) + (values[4] || 0)

            if (previousTotal >= 0 && total > previousTotal) {
                const totalDelta = total - previousTotal
                const idleDelta = idle - previousIdle
                cpuUsage = Math.max(0, Math.min(1, 1 - idleDelta / totalDelta))
                cpuReady = true
            }
            previousTotal = total
            previousIdle = idle
        }

        const totalMatch = output.match(/^MemTotal:\s+(\d+)/m)
        const availableMatch = output.match(/^MemAvailable:\s+(\d+)/m)
        if (totalMatch && availableMatch) {
            const total = Number(totalMatch[1])
            const available = Number(availableMatch[1])
            if (total > 0) {
                ramUsage = Math.max(0, Math.min(1, (total - available) / total))
                ramReady = true
            }
        }
    }

    Process {
        id: statsProcess
        command: ["sh", "-c", "head -n 1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.updateStats(this.text)
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.visible
        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 7

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "PERFORMANCE"
            color: Styling.Theme.textSecondary
            font.pixelSize: 13
            font.bold: true
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            ArcGauge {
                width: 96
                height: 110
                label: "CPU"
                value: root.cpuUsage
                ready: root.cpuReady
                animated: true
                utilizationColors: true
                minimumVisibleFraction: 0.05
            }

            ArcGauge {
                width: 96
                height: 110
                label: "RAM"
                value: root.ramUsage
                ready: root.ramReady
                animated: true
                utilizationColors: true
                minimumVisibleFraction: 0.05
            }
        }
    }
}
