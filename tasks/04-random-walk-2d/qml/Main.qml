import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 760
    title: "Point Walk Simulation"
    color: Theme.bg

    property int activeTab: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── LEFT SIDEBAR ─────────────────────────────────────────────────────
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
                        text: "POINT WALK\nSIMULATOR"
                        font.pixelSize: 18; font.letterSpacing: 3; font.bold: true
                        color: Theme.txt; lineHeight: 1.3
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: 32; height: 3; color: Theme.accent; radius: 2 }
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "h  (x step size)"
                    value: walk_controller.h
                    from: 0.1; to: 5.0; stepSize: 0.1
                    sliderColor: Theme.accent
                    onMoved: function(v) { walk_controller.set_h(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "Y  (start y)"
                    value: walk_controller.start_y
                    from: -10; to: 10; stepSize: 0.5
                    sliderColor: Theme.warn
                    onMoved: function(v) { walk_controller.set_start_y(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "steps  (x count)"
                    value: walk_controller.x_steps
                    from: 5; to: 100; stepSize: 1
                    sliderColor: Theme.success
                    onMoved: function(v) { walk_controller.set_x_steps(Math.round(v)) }
                }

                SectionLabel { Layout.fillWidth: true; text: "DISTRIBUTION" }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 6
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        ModeTab { Layout.fillWidth: true; label: "UNIFORM";   highlight: walk_controller.distribution === "uniform";   accent: Theme.accent;  onClicked: walk_controller.set_distribution("uniform") }
                        ModeTab { Layout.fillWidth: true; label: "BINOMIAL";  highlight: walk_controller.distribution === "binomial";  accent: Theme.warn;    onClicked: walk_controller.set_distribution("binomial") }
                    }
                    RowLayout {
                        Layout.fillWidth: true; spacing: 6
                        ModeTab { Layout.fillWidth: true; label: "GEOMETRIC"; highlight: walk_controller.distribution === "geometric"; accent: Theme.success; onClicked: walk_controller.set_distribution("geometric") }
                        ModeTab { Layout.fillWidth: true; label: "TRIANGULAR";highlight: walk_controller.distribution === "triangular";accent: Theme.danger;  onClicked: walk_controller.set_distribution("triangular") }
                    }
                }

                // Distribution-specific parameters (shown conditionally)
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "binomial"
                    label: "trials  (binomial n)"
                    value: walk_controller.binom_trials
                    from: 1; to: 20; stepSize: 1
                    sliderColor: Theme.warn
                    onMoved: function(v) { walk_controller.set_binom_trials(Math.round(v)) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "binomial"
                    label: "p  (binomial prob)"
                    value: walk_controller.binom_p
                    from: 0.01; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.warn
                    onMoved: function(v) { walk_controller.set_binom_p(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "geometric"
                    label: "p  (geometric prob)"
                    value: walk_controller.geom_p
                    from: 0.01; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.success
                    onMoved: function(v) { walk_controller.set_geom_p(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "triangular"
                    label: "a  (tri min)"
                    value: walk_controller.tri_a
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_a(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "triangular"
                    label: "b  (tri peak)"
                    value: walk_controller.tri_b
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_b(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "triangular"
                    label: "c  (tri max)"
                    value: walk_controller.tri_c
                    from: -20; to: 20; stepSize: 0.1
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_c(v) }
                }

                SectionLabel { Layout.fillWidth: true; text: "STEP VALUES" }

                // Editable steps field
                Rectangle {
                    Layout.fillWidth: true; height: 36; radius: 4
                    color: Theme.card; border.color: stepsField.activeFocus ? Theme.accent : Theme.border; border.width: 1
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                        Text { text: "s:"; color: Theme.muted; font.pixelSize: 11 }
                        TextInput {
                            id: stepsField
                            Layout.fillWidth: true
                            text: walk_controller.step_values.map(function(v){ return v.toFixed(1) }).join(", ")
                            color: Theme.txt; font.pixelSize: 11
                            selectByMouse: true
                            onEditingFinished: walk_controller.set_steps(text)
                            Keys.onReturnPressed: walk_controller.set_steps(text)
                        }
                    }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "l  (target crossings)"
                    value: walk_controller.l_crossings
                    from: 0; to: 20; stepSize: 1
                    sliderColor: Theme.warn
                    onMoved: function(v) { walk_controller.set_l(Math.round(v)) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "N  (batch simulations)"
                    value: walk_controller.N_sims
                    from: 10; to: 2000; stepSize: 10
                    sliderColor: Theme.accent
                    onMoved: function(v) { walk_controller.set_N(Math.round(v)) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "K  (log history)"
                    value: walk_controller.K
                    from: 1; to: 100; stepSize: 1
                    sliderColor: Theme.muted
                    onMoved: function(v) { walk_controller.set_K(Math.round(v)) }
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 8

                    AppButton {
                        Layout.fillWidth: true
                        label: "▶  Run single"
                        accent: Theme.accent
                        enabled: !walk_controller.batch_running
                        opacity: enabled ? 1.0 : 0.5
                        onClicked: walk_controller.run_single()
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: walk_controller.batch_running ? "⏳  Running..." : "⚡  Run " + walk_controller.N_sims + " batch"
                        accent: Theme.warn
                        enabled: !walk_controller.batch_running
                        opacity: enabled ? 1.0 : 0.5
                        onClicked: walk_controller.run_batch()
                    }

                    AppButton {
                        Layout.fillWidth: true
                        label: "📂  Load config.json"
                        accent: Theme.success
                        onClicked: filePicker.open()
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    ModeTab { Layout.fillWidth: true; label: "TRAJECTORY"; highlight: root.activeTab === 0; accent: Theme.accent; onClicked: root.activeTab = 0 }
                    ModeTab { Layout.fillWidth: true; label: "LOG";        highlight: root.activeTab === 1; accent: Theme.warn;   onClicked: root.activeTab = 1 }
                    ModeTab { Layout.fillWidth: true; label: "STATS";      highlight: root.activeTab === 2; accent: Theme.success;onClicked: root.activeTab = 2 }
                }
            }
        }

        // ── MAIN CONTENT ─────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                // ── TAB 0: Trajectory ─────────────────────────────────────────
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Text {
                                text: "TRAJECTORY"
                                color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true
                            }
                            Text {
                                visible: walk_controller.batch_n > 0
                                text: "last of " + walk_controller.batch_n + " batch runs"
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.6)
                                font.pixelSize: 11
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: "dist: " + walk_controller.distribution.toUpperCase()
                                color: Theme.accent; font.pixelSize: 11; font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.card; border.color: Theme.border; border.width: 1; radius: 8

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: walk_controller.batch_running
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⏳"; font.pixelSize: 48 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Computing..."; color: Theme.muted; font.pixelSize: 14 }
                            }

                            TrajectoryChart {
                                anchors.fill: parent
                                anchors.margins: 16
                                visible: !walk_controller.batch_running
                                trajectory:   walk_controller.last_trajectory
                                l_crossings:  walk_controller.last_trajectory.length > 0
                                    ? (function() {
                                        var pts = walk_controller.last_trajectory
                                        var cnt = 0
                                        for (var i = 1; i < pts.length; i++) {
                                            var a = pts[i-1].y, b = pts[i].y
                                            if (a === 0 && b !== 0) { cnt++; continue }
                                            if (b === 0) { cnt++; continue }
                                            if ((a > 0) !== (b > 0)) cnt++
                                        }
                                        return cnt
                                    })()
                                    : 0
                                h_step: walk_controller.h
                            }
                        }
                    }
                }

                // ── TAB 1: Log ────────────────────────────────────────────────
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "SIMULATION LOG"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true; Layout.fillWidth: true }
                            Text {
                                text: "last " + walk_controller.K + " runs"
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.6); font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.card; border.color: Theme.border; border.width: 1; radius: 8
                            clip: true

                            Column {
                                anchors.centerIn: parent; spacing: 12
                                visible: walk_controller.log_entries.length === 0
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📋"; font.pixelSize: 48 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No simulations yet"; color: Theme.muted; font.pixelSize: 14 }
                            }

                            ListView {
                                anchors.fill: parent
                                anchors.margins: 8
                                visible: walk_controller.log_entries.length > 0
                                model: walk_controller.log_entries
                                clip: true
                                spacing: 4

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle { radius: 3; color: Theme.border }
                                }

                                header: Rectangle {
                                    width: parent.width - 8; height: 32; radius: 4
                                    color: Theme.surface
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                        Text { text: "#";           color: Theme.muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 50 }
                                        Text { text: "DIST";        color: Theme.muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 90 }
                                        Text { text: "START Y";     color: Theme.muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 80 }
                                        Text { text: "X STEPS";     color: Theme.muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 80 }
                                        Text { text: "CROSSINGS";   color: Theme.muted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1; Layout.fillWidth: true }
                                    }
                                }

                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: parent ? parent.width - 8 : 0; height: 36; radius: 4
                                    color: index % 2 === 0 ? Theme.surface : "transparent"
                                    border.color: modelData.crossings === walk_controller.l_crossings
                                        ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.3)
                                        : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                                        Text { text: modelData.sim_index;               color: Theme.muted;  font.pixelSize: 12; Layout.preferredWidth: 50 }
                                        Text { text: modelData.dist_name.toUpperCase(); color: Theme.accent; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: 90 }
                                        Text { text: modelData.start_y.toFixed(1);      color: Theme.muted;  font.pixelSize: 12; Layout.preferredWidth: 80 }
                                        Text { text: modelData.x_steps;                 color: Theme.muted;  font.pixelSize: 12; Layout.preferredWidth: 80 }
                                        Text {
                                            text: modelData.crossings
                                            color: modelData.crossings === walk_controller.l_crossings
                                                ? Theme.success
                                                : (modelData.crossings === 0 ? Theme.muted : Theme.warn)
                                            font.pixelSize: 13; font.bold: true
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── TAB 2: Stats ──────────────────────────────────────────────
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        Text { text: "BATCH STATISTICS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 40

                            ColumnLayout {
                                spacing: 2
                                Text { text: "P(CROSSINGS = l)"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: walk_controller.batch_n > 0
                                        ? walk_controller.crossing_prob.toFixed(5)
                                        : "—"
                                    color: Theme.success; font.pixelSize: 36; font.bold: true
                                }
                                Text {
                                    text: walk_controller.batch_n > 0
                                        ? walk_controller.crossing_count + " / " + walk_controller.batch_n + " runs  (l=" + walk_controller.l_crossings + ")"
                                        : "run a batch first"
                                    color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.6); font.pixelSize: 12
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: "BATCH SIZE"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: walk_controller.batch_n > 0 ? walk_controller.batch_n : "—"
                                    color: Theme.accent; font.pixelSize: 36; font.bold: true
                                }
                                Text { text: "N simulations"; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6); font.pixelSize: 12 }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: "TARGET l"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text { text: walk_controller.l_crossings; color: Theme.warn; font.pixelSize: 36; font.bold: true }
                                Text {
                                    text: walk_controller.l_crossings === 0 ? "zero crossings" : "x-axis crossings"
                                    color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.6); font.pixelSize: 12
                                }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10
                            Text { text: "ACTIVE CONFIGURATION"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 8
                                Text { text: "h  (x step)";        color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.h.toFixed(2); color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "Y  (start y)";        color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.start_y.toFixed(2); color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "x steps per run";     color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.x_steps; color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "Distribution";         color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.distribution.toUpperCase(); color: Theme.accent; font.pixelSize: 12; font.bold: true }
                                // Binomial params
                                Text { visible: walk_controller.distribution === "binomial"; text: "trials  (binomial n)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "binomial"; text: walk_controller.binom_trials; color: Theme.warn; font.pixelSize: 12; font.bold: true }
                                Text { visible: walk_controller.distribution === "binomial"; text: "p  (binomial prob)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "binomial"; text: walk_controller.binom_p.toFixed(2); color: Theme.warn; font.pixelSize: 12; font.bold: true }
                                // Geometric params
                                Text { visible: walk_controller.distribution === "geometric"; text: "p  (geometric prob)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "geometric"; text: walk_controller.geom_p.toFixed(2); color: Theme.success; font.pixelSize: 12; font.bold: true }
                                // Triangular params
                                Text { visible: walk_controller.distribution === "triangular"; text: "a  (tri min)";  color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "triangular"; text: walk_controller.tri_a.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { visible: walk_controller.distribution === "triangular"; text: "b  (tri peak)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "triangular"; text: walk_controller.tri_b.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { visible: walk_controller.distribution === "triangular"; text: "c  (tri max)";  color: Theme.muted; font.pixelSize: 12 }
                                Text { visible: walk_controller.distribution === "triangular"; text: walk_controller.tri_c.toFixed(2); color: Theme.danger; font.pixelSize: 12; font.bold: true }
                                Text { text: "s values";             color: Theme.muted; font.pixelSize: 12 }
                                Text {
                                    text: {
                                        var sv = walk_controller.step_values
                                        return sv.length > 0 ? "[" + sv.map(function(v){ return v.toFixed(1) }).join(", ") + "]" : "—"
                                    }
                                    color: Theme.txt; font.pixelSize: 12; font.bold: true
                                }
                                Text { text: "K  (log depth)";      color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.K;      color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "l  (target crossings)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.l_crossings; color: Theme.warn; font.pixelSize: 12; font.bold: true }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "DISTRIBUTION INFO"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    var d = walk_controller.distribution
                                    if (d === "uniform")    return "s ~ Uniform{s₁,…,sₙ}  —  each step value is equally likely."
                                    if (d === "binomial")   return "s ~ Binomial(" + walk_controller.binom_trials + ", " + walk_controller.binom_p.toFixed(2) + ") mod n  —  index mapped onto step values."
                                    if (d === "geometric")  return "s ~ TruncGeometric(p=" + walk_controller.geom_p.toFixed(2) + ") on {s₁,…,sₙ}  —  P(k) ∝ (1−p)^k·p, renormalized."
                                    return "s ~ DiscreteTriangular(a=" + walk_controller.tri_a.toFixed(2) + ", b=" + walk_controller.tri_b.toFixed(2) + ", c=" + walk_controller.tri_c.toFixed(2) + ")  —  continuous Triangular CDF-inverted, snapped to nearest step."
                                }
                                color: Theme.muted; font.pixelSize: 12; wrapMode: Text.WordWrap
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ── Status bar ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true; height: 44; color: Theme.surface
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                    Text { text: "h=" + walk_controller.h.toFixed(1) + "  Y=" + walk_controller.start_y.toFixed(1) + "  steps=" + walk_controller.x_steps; color: Theme.muted; font.pixelSize: 12 }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "dist: " + walk_controller.distribution.toUpperCase(); color: Theme.accent; font.pixelSize: 12; font.bold: true }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "l=" + walk_controller.l_crossings; color: Theme.warn; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: walk_controller.batch_n > 0
                        text: "P(crossings=" + walk_controller.l_crossings + ") = " + walk_controller.crossing_prob.toFixed(5) + "  over " + walk_controller.batch_n + " runs"
                        color: Theme.success; font.pixelSize: 12; font.bold: true
                    }
                    Text {
                        visible: walk_controller.batch_running
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
            walk_controller.load_config(path)
        }
    }
}
