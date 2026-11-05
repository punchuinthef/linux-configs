import QtQuick
import Quickshell.Io

QtObject {
    id: service

    property bool busy: false
    property string error: ""
    property var drives: ({})
    property string lastUpdated: ""
    property bool refreshQueued: false

    function refresh() {
        if (busy) {
            refreshQueued = true
            return
        }
        error = ""
        busy = true
        probe.running = true
    }

    property Process probe: Process {
        // All paths are fixed by the shell configuration; no user input is interpolated.
        command: ["sh", "-c", `
            for entry in 'home|/home' 'games|/games' 'music|/music' 'backup|/run/media/radio/SudoSaveMe'; do
                key=\${entry%%|*}
                path=\${entry#*|}
                if mountpoint -q -- "$path"; then
                    values=$(df -P -B1 -- "$path" 2>/dev/null | awk 'NR==2 {print $2 "|" $3}')
                    if [ -n "$values" ]; then
                        printf '%s|mounted|%s\\n' "$key" "$values"
                    else
                        printf '%s|error|0|0\\n' "$key"
                    fi
                else
                    printf '%s|unmounted|0|0\\n' "$key"
                fi
            done
        `]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const result = {}
                for (const line of text.trim().split("\n")) {
                    const parts = line.trim().split("|")
                    if (parts.length !== 4) continue
                    const total = Number(parts[2])
                    const used = Number(parts[3])
                    result[parts[0]] = {
                        mounted: parts[1] === "mounted",
                        status: parts[1],
                        total: total,
                        used: used,
                        percent: total > 0 ? Math.min(100, Math.round(100 * used / total)) : 0
                    }
                }
                service.drives = result
                service.lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss")
                service.busy = false
                if (service.refreshQueued) {
                    service.refreshQueued = false
                    service.refresh()
                }
            }
        }
    }
}
