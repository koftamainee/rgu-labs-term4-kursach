import QtQuick
import QtQuick.Layouts
import "."

Rectangle {
    id: tab
    property string label: ""
    property bool highlight: false
    property color accent: Theme.accent
    signal clicked()

    height: 32
    radius: 4
    color: highlight ? accent : "transparent"
    border.color: highlight ? accent : Theme.border
    border.width: 1

    Text {
        anchors.centerIn: parent
        text: tab.label
        color: Theme.txt
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: tab.clicked()
    }
}
