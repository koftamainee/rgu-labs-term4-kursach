import QtQuick
import "."

Rectangle {
    id: sb2
    property string label: ""
    property int mode: 0
    property int currentMode: 0
    property color accent: Theme.accent
    signal clicked()

    height: 32
    width: labelText.implicitWidth + 24
    radius: 4
    color: currentMode === mode ? Qt.rgba(accent.r, accent.g, accent.b, 0.25) : "transparent"
    border.color: currentMode === mode ? accent : Theme.border
    border.width: 1

    Text {
        id: labelText
        anchors.centerIn: parent
        text: sb2.label
        color: sb2.currentMode === sb2.mode ? sb2.accent : Theme.muted
        font.pixelSize: 11
        font.bold: sb2.currentMode === sb2.mode
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sb2.clicked()
    }
}
