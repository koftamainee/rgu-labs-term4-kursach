import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 760
    title: "Staircase Figure Simulation"
    color: Theme.bg

    property int    activeTab:  0
    property int    perPage:    6
    property var    pageData:   []

    function refreshPage() {
        pageData = sim_controller.get_current_page_data(perPage)
    }

    Connections {
        target: sim_controller
        function onBatch_done()  { root.refreshPage() }
        function onPage_changed() { root.refreshPage() }
        function onConfig_loaded() { root.pageData = [] }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 290
            color: Theme.surface
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Item {
                    Layout.fillWidth: true; height: 56
                    Text {
                        text: "STAIRCASE\nSIMULATOR"
                        font.pixelSize: 18; font.letterSpacing: 3; font.bold: true
                        color: Theme.txt; lineHeight: 1.3
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: 32; height: 3; color: Theme.accent; radius: 2 }
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "M  (segment length)"
                    value: sim_controller.M
                    from: 2; to: 40; stepSize: 1
                    sliderColor: Theme.accent
                    onMoved: function(v) { sim_controller.set_M(Math.round(v)) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "h  (step size)"
                    value: sim_controller.h
                    from: 0.5; to: 5; stepSize: 0.5
                    sliderColor: Theme.warn
                    onMoved: function(v) { sim_controller.set_h(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "τ  (value unit)"
                    value: sim_controller.tau
                    from: 0.1; to: 5; stepSize: 0.1
                    sliderColor: Theme.success
                    onMoved: function(v) { sim_controller.set_tau(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "n  (max value index)"
                    value: sim_controller.n_values
                    from: 2; to: 16; stepSize: 1
                    sliderColor: Theme.accent
                    onMoved: function(v) { sim_controller.set_n_values(Math.round(v)) }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 4
                    color: Theme.card; border.color: Theme.border; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Text { text: "segments  M/h"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                        Text { text: sim_controller.segment_count; color: Theme.accent; font.pixelSize: 11; font.bold: true }
                    }
                }

                SectionLabel { Layout.fillWidth: true; text: "DISTRIBUTION" }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6

                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        ModeTab { Layout.fillWidth: true; label: "UNIFORM";   highlight: sim_controller.distribution === "uniform";   accent: Theme.accent;  onClicked: sim_controller.set_distribution("uniform") }
                        ModeTab { Layout.fillWidth: true; label: "BINOMIAL";  highlight: sim_controller.distribution === "binomial";  accent: Theme.warn;    onClicked: sim_controller.set_distribution("binomial") }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        ModeTab { Layout.fillWidth: true; label: "GEOMETRIC"; highlight: sim_controller.distribution === "geometric"; accent: Theme.success; onClicked: sim_controller.set_distribution("geometric") }
                        ModeTab { Layout.fillWidth: true; label: "TRIANGULAR";highlight: sim_controller.distribution === "triangular";accent: Theme.danger;  onClicked: sim_controller.set_distribution("triangular") }
                    }
                }

                // Distribution-specific parameters (shown conditionally)
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "binomial"
                    label: "trials  (binomial n)"
                    value: sim_controller.binom_trials
                    from: 1; to: 20; stepSize: 1
                    sliderColor: Theme.warn
                    onMoved: function(v) { sim_controller.set_binom_trials(Math.round(v)) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "binomial"
                    label: "p  (binomial prob)"
                    value: sim_controller.binom_p
                    from: 0.01; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.warn
                    onMoved: function(v) { sim_controller.set_binom_p(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "geometric"
                    label: "p  (geometric prob)"
                    value: sim_controller.geom_p
                    from: 0.01; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.success
                    onMoved: function(v) { sim_controller.set_geom_p(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "triangular"
                    label: "a  (tri min)"
                    value: sim_controller.tri_a
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { sim_controller.set_tri_a(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "triangular"
                    label: "b  (tri peak)"
                    value: sim_controller.tri_b
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { sim_controller.set_tri_b(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: sim_controller.distribution === "triangular"
                    label: "c  (tri max)"
                    value: sim_controller.tri_c
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { sim_controller.set_tri_c(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "N  (generations)"
                    value: sim_controller.N_generations
                    from: 10; to: 2000; stepSize: 10
                    sliderColor: Theme.accent
                    onMoved: function(v) { sim_controller.set_N(Math.round(v)) }
                }

                AppButton {
                    Layout.fillWidth: true
                    label: sim_controller.batch_running ? "⏳  Running..." : "▶  Run " + sim_controller.N_generations + " generations"
                    accent: Theme.accent
                    enabled: !sim_controller.batch_running
                    opacity: enabled ? 1.0 : 0.5
                    onClicked: sim_controller.run_batch()
                }

                AppButton {
                    Layout.fillWidth: true
                    label: "📂  Load config.json"
                    accent: Theme.warn
                    onClicked: filePicker.open()
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true; height: 1; color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    ModeTab { Layout.fillWidth: true; label: "CHARTS";  highlight: root.activeTab === 0; accent: Theme.accent; onClicked: root.activeTab = 0 }
                    ModeTab { Layout.fillWidth: true; label: "STATS";   highlight: root.activeTab === 1; accent: Theme.warn;   onClicked: root.activeTab = 1 }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true; spacing: 10

                            Text {
                                text: sim_controller.batch_n > 0
                                    ? "Distribution: " + sim_controller.distribution.toUpperCase() + "   ξ ∈ {0, τ, 2τ…nτ}   segments=" + sim_controller.segment_count
                                    : "Run a simulation to see step figures"
                                color: Theme.muted; font.pixelSize: 12
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: sim_controller.batch_n > 0
                                text: "P(↑) = " + sim_controller.increasing_prob.toFixed(4)
                                color: Theme.success; font.pixelSize: 13; font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.card; border.color: Theme.border; border.width: 1; radius: 8

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: sim_controller.batch_running
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⏳"; font.pixelSize: 48 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Computing..."; color: Theme.muted; font.pixelSize: 14 }
                            }

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: root.pageData.length === 0 && !sim_controller.batch_running
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📊"; font.pixelSize: 48 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Click \"Run\" to generate step figures"; color: Theme.muted; font.pixelSize: 14 }
                            }

                            GridLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                columns: 3
                                rowSpacing: 10
                                columnSpacing: 10
                                visible: root.pageData.length > 0 && !sim_controller.batch_running

                                Repeater {
                                    model: root.pageData.length

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: Theme.surface
                                        border.color: root.pageData[index] && root.pageData[index].strictly_increasing
                                            ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.4)
                                            : Theme.border
                                        border.width: 1
                                        radius: 6

                                        StaircaseChart {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            steps:               root.pageData[index] ? root.pageData[index].steps : []
                                            strictly_increasing: root.pageData[index] ? root.pageData[index].strictly_increasing : false
                                            generation_index:    root.pageData[index] ? root.pageData[index].index : 0
                                            tau: sim_controller.tau
                                            h:   sim_controller.h
                                            seg_m: sim_controller.M
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: sim_controller.page_count > 0 && !sim_controller.batch_running
                            spacing: 8

                            AppButton {
                                label: "◀"
                                accent: Theme.accent
                                width: 48; height: 32
                                enabled: sim_controller.current_page > 0
                                opacity: enabled ? 1.0 : 0.3
                                onClicked: sim_controller.prev_page()
                            }

                            Item { Layout.fillWidth: true }

                            Repeater {
                                model: Math.min(sim_controller.page_count, 12)
                                delegate: Rectangle {
                                    property int pageIndex: {
                                        var pc = sim_controller.page_count
                                        if (pc <= 12) return index
                                        var cp = sim_controller.current_page
                                        var start = Math.max(0, Math.min(cp - 5, pc - 12))
                                        return start + index
                                    }
                                    width: 28; height: 28; radius: 4
                                    color: sim_controller.current_page === pageIndex
                                        ? Theme.accent
                                        : "transparent"
                                    border.color: sim_controller.current_page === pageIndex
                                        ? Theme.accent
                                        : Theme.border
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: pageIndex + 1
                                        color: Theme.txt
                                        font.pixelSize: 10; font.bold: true
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sim_controller.goto_page(pageIndex)
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            AppButton {
                                label: "▶"
                                accent: Theme.accent
                                width: 48; height: 32
                                enabled: sim_controller.current_page < sim_controller.page_count - 1
                                opacity: enabled ? 1.0 : 0.3
                                onClicked: sim_controller.next_page()
                            }
                        }

                        Text {
                            visible: sim_controller.page_count > 0 && !sim_controller.batch_running
                            Layout.alignment: Qt.AlignHCenter
                            text: "Page " + (sim_controller.current_page + 1) + " of " + sim_controller.page_count
                                + "   ·   " + sim_controller.batch_n + " generations total"
                            color: Theme.muted; font.pixelSize: 11
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        Text {
                            text: "BATCH STATISTICS"
                            color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 0

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "P(STRICTLY INCREASING)"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: sim_controller.batch_n > 0
                                        ? sim_controller.increasing_prob.toFixed(5)
                                        : "—"
                                    color: Theme.success; font.pixelSize: 36; font.bold: true
                                }
                                Text {
                                    text: sim_controller.batch_n > 0
                                        ? sim_controller.increasing_count + " / " + sim_controller.batch_n + " runs"
                                        : "run a simulation first"
                                    color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.6)
                                    font.pixelSize: 12
                                }
                            }

                            StatDivider { Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12 }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "TOTAL RUNS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: sim_controller.batch_n > 0 ? sim_controller.batch_n : "—"
                                    color: Theme.accent; font.pixelSize: 36; font.bold: true
                                }
                                Text { text: "N generations"; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6); font.pixelSize: 12 }
                            }

                            StatDivider { Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12 }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 2
                                Text { text: "SEGMENTS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text { text: sim_controller.segment_count; color: Theme.warn; font.pixelSize: 36; font.bold: true }
                                Text { text: "M/h = " + sim_controller.M + "/" + sim_controller.h.toFixed(1); color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.6); font.pixelSize: 12 }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10

                            Text { text: "ACTIVE CONFIGURATION"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }

                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 8

                                Text { text: "M  (interval length)";    color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.M;           color: Theme.txt;   font.pixelSize: 12; font.bold: true }
                                Text { text: "h  (sub-interval size)";  color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.h.toFixed(2); color: Theme.txt;  font.pixelSize: 12; font.bold: true }
                                Text { text: "τ  (value unit)";          color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.tau.toFixed(2); color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "n  (max index, ξ ∈ {0…nτ})"; color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.n_values;    color: Theme.txt;   font.pixelSize: 12; font.bold: true }
                                Text { text: "Distribution";             color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.distribution.toUpperCase(); color: Theme.accent; font.pixelSize: 12; font.bold: true }
                                // Binomial params
                                Text { visible: sim_controller.distribution === "binomial"; text: "trials  (binomial n)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "binomial"; text: sim_controller.binom_trials; color: Theme.warn; font.pixelSize: 12; font.bold: true }
                                Text { visible: sim_controller.distribution === "binomial"; text: "p  (binomial prob)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "binomial"; text: sim_controller.binom_p.toFixed(2); color: Theme.warn; font.pixelSize: 12; font.bold: true }
                                // Geometric params
                                Text { visible: sim_controller.distribution === "geometric"; text: "p  (geometric prob)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "geometric"; text: sim_controller.geom_p.toFixed(2); color: Theme.success; font.pixelSize: 12; font.bold: true }
                                // Triangular params
                                Text { visible: sim_controller.distribution === "triangular"; text: "a  (tri min)";  color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "triangular"; text: sim_controller.tri_a.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { visible: sim_controller.distribution === "triangular"; text: "b  (tri peak)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "triangular"; text: sim_controller.tri_b.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { visible: sim_controller.distribution === "triangular"; text: "c  (tri max)";  color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: sim_controller.distribution === "triangular"; text: sim_controller.tri_c.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { text: "N (generations)";          color: Theme.muted; font.pixelSize: 12 }
                                Text { text: sim_controller.N_generations; color: Theme.txt; font.pixelSize: 12; font.bold: true }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "DISTRIBUTION INFO"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var d = sim_controller.distribution
                                    if (d === "uniform")
                                        return "ξ ~ Uniform{0, τ, 2τ, …, nτ}  —  each of the (n+1) values is equally likely."
                                    if (d === "binomial")
                                        return "ξ ~ Binomial(" + sim_controller.binom_trials + ", " + sim_controller.binom_p.toFixed(2) + ") mod (n+1) · τ  —  mapped onto the value set."
                                    if (d === "geometric")
                                        return "ξ ~ TruncGeometric(p=" + sim_controller.geom_p.toFixed(2) + ") on {0,1,…,n}·τ  —  P(k) ∝ (1−p)^k · p, renormalized."
                                    return "ξ ~ Triangular(a=" + sim_controller.tri_a.toFixed(2) + ", b=" + sim_controller.tri_b.toFixed(2) + ", c=" + sim_controller.tri_c.toFixed(2) + ")  —  CDF-inverted, snapped to nearest k·τ."
                                }
                                color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 44; color: Theme.surface
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                    Text { text: "M=" + sim_controller.M + "  h=" + sim_controller.h.toFixed(1) + "  τ=" + sim_controller.tau.toFixed(1) + "  n=" + sim_controller.n_values; color: Theme.muted; font.pixelSize: 12 }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "dist: " + sim_controller.distribution.toUpperCase(); color: Theme.accent; font.pixelSize: 12; font.bold: true }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "segments: " + sim_controller.segment_count; color: Theme.txt; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: sim_controller.batch_n > 0
                        text: "P(↑) = " + sim_controller.increasing_prob.toFixed(5) + "  over " + sim_controller.batch_n + " runs"
                        color: Theme.success; font.pixelSize: 12; font.bold: true
                    }
                    Text {
                        visible: sim_controller.batch_running
                        text: "● COMPUTING"
                        color: Theme.warn; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                    }
                }
            }
        }
    }

    FilePickerDialog {
        id: filePicker
        onAccepted: function(filePath) {
            var path = filePath.replace(/^file:\/\//, "")
            sim_controller.load_config(path)
        }
    }
}
