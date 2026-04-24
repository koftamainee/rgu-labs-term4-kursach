import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 760
    title: "Complex Plane Walk Simulation"
    color: Theme.bg

    property int activeTab: 0

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
                        text: "COMPLEX WALK\nSIMULATOR"
                        font.pixelSize: 18; font.letterSpacing: 3; font.bold: true
                        color: Theme.txt; lineHeight: 1.3
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: 32; height: 3; color: Theme.accent; radius: 2 }
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "ρ  (step radius)"
                    value: walk_controller.rho
                    from: 0.1; to: 5.0; stepSize: 0.1
                    sliderColor: Theme.accent
                    onMoved: function(v) { walk_controller.set_rho(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "n  (directions)"
                    value: walk_controller.n
                    from: 4; to: 32; stepSize: 1
                    sliderColor: Theme.warn
                    onMoved: function(v) { walk_controller.set_n(Math.round(v)) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "K  (max steps per run)"
                    value: walk_controller.K
                    from: 10; to: 5000; stepSize: 10
                    sliderColor: Theme.success
                    onMoved: function(v) { walk_controller.set_K(Math.round(v)) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "ε  (return threshold)"
                    value: walk_controller.epsilon
                    from: 0.001; to: 1.0; stepSize: 0.001
                    sliderColor: Theme.muted
                    onMoved: function(v) { walk_controller.set_epsilon(v) }
                }

                SectionLabel { Layout.fillWidth: true; text: "DISTRIBUTION  (ξ ∈ Zₙ)" }

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
                    from: 0.0; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_a(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "triangular"
                    label: "b  (tri peak)"
                    value: walk_controller.tri_b
                    from: 0.0; to: 0.99; stepSize: 0.01
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_b(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    visible: walk_controller.distribution === "triangular"
                    label: "c  (tri max)"
                    value: walk_controller.tri_c
                    from: 0.01; to: 1.0; stepSize: 0.01
                    sliderColor: Theme.danger
                    onMoved: function(v) { walk_controller.set_tri_c(v) }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "M  (launches)"
                    value: walk_controller.M
                    from: 10; to: 5000; stepSize: 10
                    sliderColor: Theme.accent
                    onMoved: function(v) { walk_controller.set_M(Math.round(v)) }
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
                        label: walk_controller.batch_running ? "⏳  Running..." : "⚡  Run " + walk_controller.M + " launches"
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
                    ModeTab { Layout.fillWidth: true; label: "STATS";      highlight: root.activeTab === 1; accent: Theme.warn;   onClicked: root.activeTab = 1 }
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

                // ── TAB 0: Trajectory ─────────────────────────────────────────
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            Text { text: "COMPLEX PLANE TRAJECTORY"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 3; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Text {
                                visible: walk_controller.batch_n > 0
                                text: "last of " + walk_controller.batch_n + " batch runs"
                                color: Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.6); font.pixelSize: 11
                            }
                            Text {
                                text: "n=" + walk_controller.n + "  ρ=" + walk_controller.rho.toFixed(2) + "  dist: " + walk_controller.distribution.toUpperCase()
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

                            ComplexPlaneChart {
                                anchors.fill: parent
                                anchors.margins: 16
                                visible: !walk_controller.batch_running
                                path:         walk_controller.last_path
                                returned:     walk_controller.last_returned
                                return_step:  walk_controller.last_return_step
                                rho:          walk_controller.rho
                                n_dirs:       walk_controller.n
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 20
                            visible: walk_controller.last_path.length > 0 && !walk_controller.batch_running

                            Rectangle {
                                height: 36; radius: 6
                                Layout.preferredWidth: 200
                                color: walk_controller.last_returned
                                    ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.12)
                                    : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.12)
                                border.color: walk_controller.last_returned ? Theme.success : Theme.danger
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: walk_controller.last_returned
                                        ? "↩  Returned to origin"
                                        : "✗  Did not return"
                                    color: walk_controller.last_returned ? Theme.success : Theme.danger
                                    font.pixelSize: 12; font.bold: true
                                }
                            }

                            Text {
                                visible: walk_controller.last_returned
                                text: "at step " + walk_controller.last_return_step
                                color: Theme.muted; font.pixelSize: 12
                            }

                            Text {
                                visible: !walk_controller.last_returned && walk_controller.last_path.length > 0
                                text: "after " + (walk_controller.last_path.length - 1) + " steps (K=" + walk_controller.K + ")"
                                color: Theme.muted; font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }

                // ── TAB 1: Stats ──────────────────────────────────────────────
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
                                Text { text: "P(RETURN TO ORIGIN)"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: walk_controller.batch_n > 0
                                        ? walk_controller.return_prob.toFixed(5)
                                        : "—"
                                    color: Theme.success; font.pixelSize: 36; font.bold: true
                                }
                                Text {
                                    text: walk_controller.batch_n > 0
                                        ? walk_controller.return_count + " / " + walk_controller.batch_n + " launches"
                                        : "run a batch first"
                                    color: Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.6); font.pixelSize: 12
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: "LAUNCHES"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text {
                                    text: walk_controller.batch_n > 0 ? walk_controller.batch_n : "—"
                                    color: Theme.accent; font.pixelSize: 36; font.bold: true
                                }
                                Text { text: "M runs"; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6); font.pixelSize: 12 }
                            }

                            ColumnLayout {
                                spacing: 2
                                Text { text: "MAX STEPS"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                                Text { text: walk_controller.K; color: Theme.warn; font.pixelSize: 36; font.bold: true }
                                Text { text: "K per launch"; color: Qt.rgba(Theme.warn.r, Theme.warn.g, Theme.warn.b, 0.6); font.pixelSize: 12 }
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 10
                            Text { text: "ACTIVE CONFIGURATION"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                            GridLayout {
                                Layout.fillWidth: true; columns: 2; columnSpacing: 24; rowSpacing: 8
                                Text { text: "ρ  (step radius)";     color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.rho.toFixed(3); color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "n  (directions)";      color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.n;       color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "K  (max steps)";       color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.K;       color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "M  (launches)";        color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.M;       color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                Text { text: "Distribution";          color: Theme.muted; font.pixelSize: 12 }
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
                                Text { text: "ε  (return threshold)"; color: Theme.muted; font.pixelSize: 12 }
                                Text { text: walk_controller.epsilon.toFixed(6); color: Theme.txt; font.pixelSize: 12; font.bold: true }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 8
                            Text { text: "FORMULA"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true }
                            Text {
                                Layout.fillWidth: true
                                text: "z_k = z_{k-1} + ρ·(cos(2π/n · ξ) + i·sin(2π/n · ξ))\n" +
                                      "z_0 = 0,  ξ ~ " + walk_controller.distribution.toUpperCase() +
                                      (walk_controller.distribution === "binomial"
                                          ? "(" + walk_controller.binom_trials + ", " + walk_controller.binom_p.toFixed(2) + ")"
                                          : walk_controller.distribution === "geometric"
                                          ? "(p=" + walk_controller.geom_p.toFixed(2) + ")"
                                          : walk_controller.distribution === "triangular"
                                          ? "(a=" + walk_controller.tri_a.toFixed(2) + ", b=" + walk_controller.tri_b.toFixed(2) + ", c=" + walk_controller.tri_c.toFixed(2) + ")"
                                          : "") +
                                      "  →  Z_n,  n=" + walk_controller.n + ",  ρ=" + walk_controller.rho.toFixed(2)
                                color: Theme.muted; font.pixelSize: 12; font.family: "monospace"; wrapMode: Text.WordWrap
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
                    Text { text: "ρ=" + walk_controller.rho.toFixed(2) + "  n=" + walk_controller.n + "  K=" + walk_controller.K; color: Theme.muted; font.pixelSize: 12 }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "dist: " + walk_controller.distribution.toUpperCase(); color: Theme.accent; font.pixelSize: 12; font.bold: true }
                    StatDivider { height: 20; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "M=" + walk_controller.M + " launches"; color: Theme.txt; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: walk_controller.batch_n > 0
                        text: "P(return) = " + walk_controller.return_prob.toFixed(5) + "  over " + walk_controller.batch_n + " runs"
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
