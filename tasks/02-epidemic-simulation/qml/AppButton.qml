import QtQuick
import "."

Rectangle {
    id: btn
    property string label: "Button"
    property string icon: ""
    property color accent: Theme.accent
    signal clicked()

    height: 38
    radius: 6
    color: ma.containsMouse
        ? Qt.lighter(accent, 1.2)
        : Qt.rgba(accent.r, accent.g, accent.b, 0.15)
    border.color: accent
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: (btn.icon ? btn.icon + "  " : "") + btn.label
        color: ma.containsMouse ? Theme.txt : Qt.lighter(btn.accent, 1.5)
        font.pixelSize: 13
        font.bold: true
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
