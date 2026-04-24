import QtQuick
import QtQuick.Layouts
import "."

ColumnLayout {
    id: sb
    property string label: ""
    property int value: 0
    property color accent: Theme.accent
    property int fraction: 1

    spacing: 2

    Text {
        text: sb.label
        color: Theme.muted
        font.pixelSize: 10
        font.letterSpacing: 2
        font.bold: true
    }
    Text {
        text: sb.value.toLocaleString(Qt.locale(), "f", 0)
        color: sb.accent
        font.pixelSize: 26
        font.bold: true
    }
    Text {
        text: sb.fraction > 0 ? (sb.value / sb.fraction).toFixed(3) : "—"
        color: Qt.rgba(sb.accent.r, sb.accent.g, sb.accent.b, 0.6)
        font.pixelSize: 11
    }
}
