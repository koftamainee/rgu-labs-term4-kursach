import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 720
    title: "Buffon Needle Simulation"
    color: Theme.bg

    property int  activeTab:  0
    property int  batchN:     1000
    property var  curveData:  []
    property var  visualNeedles: []
    property int  visualN:    200

    Connections {
        target: needle_controller
        function onVisual_ready(needles) { root.visualNeedles = needles }
        function onParams_changed()      { root.curveData = []; root.visualNeedles = [] }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 280
            color: Theme.surface
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Item {
                    Layout.fillWidth: true; height: 56
                    Text {
                        text: "BUFFON NEEDLE\nSIMULATION"
                        font.pixelSize: 18; font.letterSpacing: 3; font.bold: true
                        color: Theme.txt; lineHeight: 1.3
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: 32; height: 3; color: Theme.accent; radius: 2 }
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "d  (line spacing)"
                    value: needle_controller.d
                    from: 0.5; to: 3.0; stepSize: 0.1
                    sliderColor: Theme.warn
                    onMoved: function(v) { needle_controller.set_d(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "L  (needle length,  L \u2264 d)"
                    value: needle_controller.l
                    from: 0.1; to: needle_controller.d; stepSize: 0.05
                    sliderColor: Theme.accent
                    onMoved: function(v) { needle_controller.set_L(v) }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 4
                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08)
                    border.color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4); border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Text { text: "L / d"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                        Text {
                            text: (needle_controller.l / needle_controller.d).toFixed(3)
                            color: Theme.accent; font.pixelSize: 11; font.bold: true
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 4
                    color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.08)
                    border.color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.4); border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Text { text: "P = 2L/(\u03c0d)"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                        Text {
                            text: needle_controller.exact_prob.toFixed(5)
                            color: Theme.warn; font.pixelSize: 11; font.bold: true
                        }
                    }
                }

                SectionLabel { Layout.fillWidth: true; text: "MODE" }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    ModeTab { Layout.fillWidth: true; label: "BATCH";  highlight: root.activeTab === 0; accent: Theme.accent; onClicked: root.activeTab = 0 }
                    ModeTab { Layout.fillWidth: true; label: "VISUAL"; highlight: root.activeTab === 1; accent: Theme.warn;   onClicked: root.activeTab = 1 }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 10
                    visible: root.activeTab === 0

                    ParamSlider {
                        Layout.fillWidth: true
                        label: "Number of throws (N)"
                        value: root.batchN; from: 100; to: 100000; stepSize: 100
                        sliderColor: Theme.accent
                        onMoved: function(v) { root.batchN = Math.round(v) }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: needle_controller.batch_running ? "\u23f3  Running..." : "\u25b6  Throw " + root.batchN.toLocaleString()
                        accent: Theme.accent
                        enabled: !needle_controller.batch_running
                        opacity: enabled ? 1.0 : 0.5
                        onClicked: needle_controller.run_batch(root.batchN)
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: "\ud83d\udd04  Reset"
                        accent: Theme.danger
                        onClicked: { needle_controller.reset(); root.curveData = [] }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 10
                    visible: root.activeTab === 1

                    ParamSlider {
                        Layout.fillWidth: true
                        label: "Needles per frame"
                        value: root.visualN; from: 10; to: 500; stepSize: 10
                        sliderColor: Theme.warn
                        onMoved: function(v) { root.visualN = Math.round(v) }
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: needle_controller.batch_running ? "\u23f3  Throwing..." : "\ud83e\uddf5  Visualize"
                        accent: Theme.warn
                        enabled: !needle_controller.batch_running
                        opacity: enabled ? 1.0 : 0.5
                        onClicked: needle_controller.run_visual(root.visualN)
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: "\ud83d\udd04  Reset"
                        accent: Theme.danger
                        onClicked: { needle_controller.reset(); root.visualNeedles = [] }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true; height: 1; color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "EXACT P";  color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                        Text {
                            text: needle_controller.exact_prob.toFixed(5)
                            color: Theme.warn; font.pixelSize: 22; font.bold: true
                        }
                    }

                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "SIM P";  color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                        Text {
                            text: needle_controller.total_count > 0 ? needle_controller.sim_prob.toFixed(5) : "\u2014"
                            color: Theme.accent; font.pixelSize: 22; font.bold: true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 0

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "TOTAL"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                        Text {
                            text: needle_controller.total_count.toLocaleString()
                            color: Theme.txt; font.pixelSize: 16; font.bold: true
                        }
                    }

                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 2
                        Text { text: "ERROR"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                        Text {
                            text: needle_controller.total_count > 0 ? needle_controller.error.toFixed(5) : "\u2014"
                            color: needle_controller.error < 0.005 ? Theme.success :
                                   needle_controller.error < 0.02  ? Theme.warn    : Theme.danger
                            font.pixelSize: 16; font.bold: true
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            Rectangle {
                Layout.fillWidth: true; height: 44; color: Theme.surface
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16

                    Text { text: "d=" + needle_controller.d.toFixed(2); color: Theme.muted; font.pixelSize: 12 }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "L=" + needle_controller.l.toFixed(2); color: Theme.muted; font.pixelSize: 12 }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "Exact P = " + needle_controller.exact_prob.toFixed(5); color: Theme.warn; font.pixelSize: 12; font.bold: true }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text {
                        visible: needle_controller.total_count > 0
                        text: "Sim P = " + needle_controller.sim_prob.toFixed(5)
                        color: Theme.accent; font.pixelSize: 12; font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: needle_controller.total_count > 0
                        text: "n=" + needle_controller.total_count.toLocaleString() + "  crossings: " + needle_controller.crosses_count.toLocaleString()
                        color: Theme.muted; font.pixelSize: 11
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 16

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.card
                            border.color: Theme.border; border.width: 1
                            radius: 8

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: needle_controller.batch_running
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\u23f3"; font.pixelSize: 48 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Running..."; color: Theme.muted; font.pixelSize: 14 }
                            }

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: needle_controller.total_count === 0 && !needle_controller.batch_running
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\ud83e\uddf5"; font.pixelSize: 48 }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Press \u00abThrow\u00bb to start the simulation"
                                    color: Theme.muted; font.pixelSize: 14
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "P = 2L/(\u03c0d) = " + needle_controller.exact_prob.toFixed(5)
                                    color: Theme.warn; font.pixelSize: 13; font.bold: true
                                }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 20
                                visible: needle_controller.total_count > 0 && !needle_controller.batch_running

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 20

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 12

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.05)
                                            border.color: Theme.border; border.width: 1
                                            radius: 6

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 16
                                                spacing: 8

                                                Text { text: "RESULTS"; color: Theme.accent; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 2
                                                        Text { text: "TOTAL THROWS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true }
                                                        Text { text: needle_controller.total_count.toLocaleString(); color: Theme.txt; font.pixelSize: 24; font.bold: true }
                                                    }
                                                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 2;
                                                        Text { text: "CROSSINGS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true }
                                                        Text { text: needle_controller.crosses_count.toLocaleString(); color: Theme.danger; font.pixelSize: 24; font.bold: true }
                                                        Text {
                                                            text: needle_controller.total_count > 0
                                                                ? Math.round(needle_controller.crosses_count * 100 / needle_controller.total_count) + "%"
                                                                : "\u2014"
                                                            color: Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.6)
                                                            font.pixelSize: 11
                                                        }
                                                    }
                                                }

                                                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 2
                                                        Text { text: "P SIMULATION"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true }
                                                        Text { text: needle_controller.sim_prob.toFixed(6); color: Theme.accent; font.pixelSize: 22; font.bold: true }
                                                    }
                                                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 4; Layout.bottomMargin: 4 }
                                                    ColumnLayout {
                                                        Layout.fillWidth: true; spacing: 2;
                                                        Text { text: "P EXACT"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true }
                                                        Text { text: needle_controller.exact_prob.toFixed(6); color: Theme.warn; font.pixelSize: 22; font.bold: true }
                                                        Text { text: "2L / (\u03c0\u00b7d)"; color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.6); font.pixelSize: 11 }
                                                    }
                                                }

                                                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                                                ColumnLayout {
                                                    Layout.fillWidth: true; spacing: 4

                                                    Text { text: "ABSOLUTE ERROR |P_sim \u2212 P_exact|"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true }

                                                    RowLayout {
                                                        spacing: 10
                                                        Text {
                                                            text: needle_controller.error.toFixed(6)
                                                            color: needle_controller.error < 0.005 ? Theme.success :
                                                                   needle_controller.error < 0.02  ? Theme.warn    : Theme.danger
                                                            font.pixelSize: 26; font.bold: true
                                                        }
                                                        Text {
                                                            text: needle_controller.error < 0.005 ? "\u2713 excellent convergence" :
                                                                  needle_controller.error < 0.02  ? "~ good convergence"        : "\u2717 more throws needed"
                                                            color: needle_controller.error < 0.005 ? Theme.success :
                                                                   needle_controller.error < 0.02  ? Theme.warn    : Theme.danger
                                                            font.pixelSize: 11; font.bold: true
                                                            Layout.alignment: Qt.AlignVCenter
                                                        }
                                                    }

                                                    Rectangle {
                                                        Layout.fillWidth: true; height: 8; radius: 4
                                                        color: Theme.card; border.color: Theme.border; border.width: 1

                                                        Rectangle {
                                                            width: Math.min(1.0, needle_controller.error / 0.1) * parent.width
                                                            height: parent.height; radius: 4
                                                            color: needle_controller.error < 0.005 ? Theme.success :
                                                                   needle_controller.error < 0.02  ? Theme.warn    : Theme.danger
                                                            Behavior on width { NumberAnimation { duration: 300 } }
                                                        }
                                                    }
                                                }

                                                Item { Layout.fillHeight: true }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: "\u03c0 \u2248 2L / (d \u00b7 P_sim) = " + (needle_controller.sim_prob > 0
                                                        ? (2.0 * needle_controller.l / (needle_controller.d * needle_controller.sim_prob)).toFixed(6)
                                                        : "\u2014")
                                                    color: Theme.muted; font.pixelSize: 12
                                                    wrapMode: Text.Wrap
                                                }
                                            }
                                        }
                                    }

                                    ProbabilityChart {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        simProb:   needle_controller.sim_prob
                                        exactProb: needle_controller.exact_prob
                                        currentL:  needle_controller.l
                                        currentD:  needle_controller.d
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        NeedleView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            needles: root.visualNeedles
                            d: needle_controller.d
                            l: needle_controller.l
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 44; color: Theme.surface
                            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 16; spacing: 16
                                Text { text: "Needles in frame: " + root.visualNeedles.length; color: Theme.muted; font.pixelSize: 12 }
                                StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                                Text {
                                    text: {
                                        var crosses = 0
                                        for (var i = 0; i < root.visualNeedles.length; i++)
                                            if (root.visualNeedles[i].crosses) crosses++
                                        return "Crossings: " + crosses
                                    }
                                    color: Theme.danger; font.pixelSize: 12; font.bold: true
                                }
                                StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                                Text {
                                    text: {
                                        var crosses = 0
                                        for (var i = 0; i < root.visualNeedles.length; i++)
                                            if (root.visualNeedles[i].crosses) crosses++
                                        return root.visualNeedles.length > 0
                                            ? "P_frame = " + (crosses / root.visualNeedles.length).toFixed(4)
                                            : "P_frame = \u2014"
                                    }
                                    color: Theme.accent; font.pixelSize: 12; font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Text { }
                            }
                        }
                    }
                }
            }
        }
    }
}
