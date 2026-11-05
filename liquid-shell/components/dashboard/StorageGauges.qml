import QtQuick
import Quickshell.Io
import "../../theme" as Styling

Item {
    id: root

    // Stable filesystem identifiers, independent of /dev/sdX ordering.
    readonly property var selected: [
        { name: "Home", uuid: "e4dacaea-8b47-4e1b-9ff7-8ea899281ec0" },
        { name: "Music", uuid: "1c9bb23c-d2b0-461d-ab1f-4c244402bcab" }
    ]

    property var drives: ({})

    function refresh() {
        if (!scan.running)
            scan.running = true
    }

    function readResults(output) {
        try {
            const tree = JSON.parse(output).blockdevices || []
            const found = {}
            function visit(nodes) {
                for (const node of nodes) {
                    if (node.uuid) {
                        const mounts = node.mountpoints || []
                        const mounted = mounts.some(m => m !== null && m !== "")
                        const raw = node["fsuse%"]
                        const pct = raw === null || raw === undefined ? NaN : parseFloat(String(raw))
                        found[node.uuid.toLowerCase()] = {
                            mounted: mounted,
                            ready: mounted && Number.isFinite(pct),
                            fraction: Number.isFinite(pct) ? Math.max(0, Math.min(1, pct / 100)) : 0
                        }
                    }
                    if (node.children)
                        visit(node.children)
                }
            }
            visit(tree)
            drives = found
        } catch (error) {
            console.warn("Storage gauges: unable to parse lsblk output:", error)
        }
    }

    Process {
        id: scan
        command: ["lsblk", "--json", "--paths", "-o", "NAME,UUID,MOUNTPOINTS,FSUSE%"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.readResults(this.text)
        }
    }

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.refresh()
    }

    onVisibleChanged: if (visible) refresh()

    Column {
        anchors.fill: parent
        spacing: 3

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "STORAGE"
            color: Styling.Theme.textSecondary
            font.pixelSize: 12
            font.bold: true
        }

        Grid {
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 2
            columnSpacing: 13
            rowSpacing: 0

            Repeater {
                model: root.selected

                delegate: Item {
                    required property var modelData
                    readonly property var info: root.drives[modelData.uuid] || null
                    width: 85
                    height: 91

                    ArcGauge {
                        width: 96
                        height: 110
                        scale: 0.72
                        transformOrigin: Item.TopLeft
                        x: (parent.width - 96 * scale) / 2
                        y: -2
                        label: ""
                        value: parent.info ? parent.info.fraction : 0
                        ready: parent.info ? parent.info.ready : false
                        animated: false
                        utilizationColors: false
                        minimumVisibleFraction: 0
                        showPercentage: false
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 59
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: parent.info && parent.info.ready
                            ? Math.round(parent.info.fraction * 100) + "%" : "—"
                        color: Styling.Theme.textPrimary
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.name
                        color: Styling.Theme.textPrimary
                        font.pixelSize: modelData.name === "SudoSaveMe" ? 10 : 11
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        text: parent.info ? (parent.info.mounted ? "" : "○") : "×"
                        color: Styling.Theme.textSecondary
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
