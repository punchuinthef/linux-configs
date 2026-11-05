import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../theme" as Styling
import Quickshell.Io

Item {
    id: dashboard

    property date currentTime: new Date()

    Process {
    id: appearanceProcess

    running: false

    onExited: (exitCode, exitStatus) => {
        console.log("Appearance manager exited:", exitCode)

        if (exitCode !== 0) {
            console.warn("Appearance manager failed.")
        }
    }
}

    Timer {
        interval: 2500
        running: dashboard.visible
        repeat: true
        onTriggered: dashboard.currentTime = new Date()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // LEFT: Dashboard widget grid
        ColumnLayout {
		id: widgetGrid	
	    	Layout.fillWidth: true
		Layout.fillHeight: true
		Layout.alignment: Qt.AlignTop
            	spacing: 12

            // TOP ROW: Clock + ID + Workspaces
            RowLayout {
                Layout.fillWidth: true
		Layout.preferredHeight: 160
		Layout.maximumHeight: 160
		Layout.fillHeight: false

                spacing: 12

                DashboardCard {
                    glassAssetLight: Qt.resolvedUrl("../../assets/glass-ui/glass-reflection-light.svg")
                    glassAssetDark: Qt.resolvedUrl("../../assets/glass-ui/glass-reflection-dark.svg")
                    	padding: 12
                    	Layout.fillWidth: true
                    	Layout.fillHeight: true
			Layout.preferredWidth: 1
			
		Column {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: Qt.formatTime(
                                dashboard.currentTime, "h:mm AP"
                            )
                            color: Styling.Theme.textPrimary
                            font.pixelSize: 30
                            font.weight: Font.Medium
                        }

                        Text {
                            text: Qt.formatDate(
                                dashboard.currentTime,
                                "dddd, MMMM d"
                            )
                            color: Styling.Theme.textSecondary
                            font.pixelSize: 13
                        }
                    }
                }

                DashboardCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0.75
                    Layout.fillHeight: true

                    SystemIdentity {
                        anchors.centerIn: parent
                    }
                }

                DashboardCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0.65
                    Layout.fillHeight: true

                    DashboardWorkspaces {
                        anchors.fill: parent
                    }
                }
            }

            // BOTTOM ROW: Appearance + Calendar + Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
		Layout.preferredHeight: 400
		spacing: 12

                DashboardCard {
                    id: appearanceCard
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1

                    AppearanceActionsCard {
                        anchors.fill: parent
                    }
                }

                CalendarCard {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 2
                    Layout.fillHeight: true 
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    spacing: 12

                    DashboardCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        PerformanceCard {
                            anchors.fill: parent
                        }
                    }

                    DashboardCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 197

                        VolumeCard {
                            anchors.fill: parent
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
    

    }

        // RIGHT: Existing Media Card
        MediaCard {
            	Layout.preferredWidth: 300
    		Layout.preferredHeight: widgetGrid.implicitHeight
    		Layout.maximumHeight: widgetGrid.implicitHeight
    		Layout.fillHeight: false
    		Layout.alignment: Qt.AlignTop
        }
    }
}

