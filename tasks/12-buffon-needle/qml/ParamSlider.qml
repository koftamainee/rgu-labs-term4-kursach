import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "."

ColumnLayout {
    id: ps
    property string label: ""
    property real value: 0.5
    property real from: 0
    property real to: 1
    property real stepSize: 0.01
    property color sliderColor: Theme.accent
    signal moved(real value)

    spacing: 4

    RowLayout {
        Text {
            text: ps.label
            color: Theme.muted
            font.pixelSize: 11
            Layout.fillWidth: true
        }
        Text {
            text: slider.value.toFixed(2)
            color: ps.sliderColor
            font.pixelSize: 11
            font.bold: true
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: ps.from
        to: ps.to
        stepSize: ps.stepSize
        value: ps.value

        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: 4
            radius: 2
            color: Theme.border
            Rectangle {
                width: slider.visualPosition * parent.width
                height: 4
                radius: 2
                color: ps.sliderColor
            }
        }

        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * slider.availableWidth - width / 2
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 14
            height: 14
            radius: 7
            color: ps.sliderColor
        }

        onMoved: ps.moved(value)
    }
}
