import QtQuick
import "../../theme" as Styling

DashboardCard {
    id: root
    padding: 10
    implicitHeight: content.implicitHeight + padding * 2

    property date today: new Date()
    property int displayedYear: today.getFullYear()
    property int displayedMonth: today.getMonth()

    function changeMonth(offset) {
        const next = new Date(displayedYear, displayedMonth + offset, 1)
        displayedYear = next.getFullYear()
        displayedMonth = next.getMonth()
    }

    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.today = new Date()
    }

    Column {
        id: content
        width: parent.width
        spacing: 8

        Item {
            width: parent.width
            height: 26

            Text {
                anchors.centerIn: parent
                text: Qt.formatDate(new Date(root.displayedYear, root.displayedMonth, 1), "MMMM yyyy")
                color: Styling.Theme.textPrimary
                font.pixelSize: 16
                font.weight: Font.Medium
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    width: 35
                    text: "‹"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea { anchors.fill: parent; onClicked: root.changeMonth(-1) }
                }
                Text {
                    width: 35
                    text: "›"
                    color: Styling.Theme.textPrimary
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    MouseArea { anchors.fill: parent; onClicked: root.changeMonth(1) }
                }
            }
        }

        Grid {
            width: parent.width
            columns: 7
            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                delegate: Text {
                    required property string modelData
                    width: content.width / 7
                    height: 21
                    text: modelData
                    color: Styling.Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 12
                }
            }
        }

        Grid {
            id: daysGrid
            width: parent.width
            columns: 7
	    spacing: 0

	    height: Math.max(
		    180, 
	    	    root.height - root.padding * 2 - 26 -21 - content.spacing * 2
	    )

            readonly property int firstWeekday: new Date(root.displayedYear, root.displayedMonth, 1).getDay()
            readonly property int daysInMonth: new Date(root.displayedYear, root.displayedMonth + 1, 0).getDate()
            readonly property int cellCount: Math.ceil((firstWeekday + daysInMonth) / 7) * 7

            Repeater {
                model: daysGrid.cellCount
                delegate: Item {
                    required property int index
                    width: daysGrid.width / 7
		    height: daysGrid.height / (daysGrid.cellCount / 7)
		    readonly property int dayNumber: index - daysGrid.firstWeekday + 1
                    readonly property bool validDay: dayNumber >= 1 && dayNumber <= daysGrid.daysInMonth
                    readonly property bool isToday: validDay &&
                        dayNumber === root.today.getDate() &&
                        root.displayedMonth === root.today.getMonth() &&
                        root.displayedYear === root.today.getFullYear()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26
                        height: 26
                        radius: 13
                        visible: parent.isToday
                        color: Styling.Theme.primary
                    }
                    Text {
                        anchors.centerIn: parent
                        text: parent.validDay ? parent.dayNumber : ""
                        color: parent.isToday ? Styling.Theme.surface : Styling.Theme.textPrimary
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
