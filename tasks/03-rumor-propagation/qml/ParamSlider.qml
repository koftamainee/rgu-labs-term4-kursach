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
    property real stepSize: 1
    property color sliderColor: Theme.accent
    property bool isInt: true
    signal moved(real value)

    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
            text: ps.label
            color: Theme.muted
            font.pixelSize: 11
            Layout.fillWidth: true
        }

        // Manual input field
        Rectangle {
            width: 72
            height: 22
            radius: 4
            color: Theme.bg
            border.color: inputField.activeFocus ? ps.sliderColor : Theme.border
            border.width: 1

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter
                color: ps.sliderColor
                font.pixelSize: 11
                font.bold: true
                selectByMouse: true
                clip: true
                text: ps.isInt ? Math.round(ps.value).toString() : ps.value.toFixed(2)

                onEditingFinished: {
                    var v = parseFloat(text)
                    if (isNaN(v)) {
                        text = ps.isInt ? Math.round(ps.value).toString() : ps.value.toFixed(2)
                        return
                    }
                    v = Math.max(ps.from, Math.min(ps.to, v))
                    text = ps.isInt ? Math.round(v).toString() : v.toFixed(2)
                    ps.moved(ps.isInt ? Math.round(v) : v)
                }

                Keys.onUpPressed: {
                    var v = parseFloat(text) + ps.stepSize
                    v = Math.min(ps.to, v)
                    text = ps.isInt ? Math.round(v).toString() : v.toFixed(2)
                    ps.moved(ps.isInt ? Math.round(v) : v)
                }

                Keys.onDownPressed: {
                    var v = parseFloat(text) - ps.stepSize
                    v = Math.max(ps.from, v)
                    text = ps.isInt ? Math.round(v).toString() : v.toFixed(2)
                    ps.moved(ps.isInt ? Math.round(v) : v)
                }
            }
        }
    }

    Slider {
        id: slider
        Layout.fillWidth: true
        from: 0
        to: 1
        value: toLog(ps.value)

        function toLog(v) {
            var lo = Math.max(ps.from, 0.0001)
            var hi = ps.to
            if (hi <= lo) { return 0 }
            return (Math.log(Math.max(v, lo)) - Math.log(lo)) / (Math.log(hi) - Math.log(lo))
        }

        function fromLog(t) {
            var lo = Math.max(ps.from, 0.0001)
            var hi = ps.to
            var v = lo * Math.pow(hi / lo, t)
            if (ps.isInt) { v = Math.round(v) }
            return Math.max(ps.from, Math.min(ps.to, v))
        }

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

        onMoved: {
            var v = fromLog(value)
            inputField.text = ps.isInt ? Math.round(v).toString() : v.toFixed(2)
            ps.moved(v)
        }
    }
}
