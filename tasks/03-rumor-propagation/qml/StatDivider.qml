import QtQuick
import "."

Item {
    property real leftPadding: 16
    property real rightPadding: 16
    width: leftPadding + 1 + rightPadding

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height
        color: Theme.border
    }
}
