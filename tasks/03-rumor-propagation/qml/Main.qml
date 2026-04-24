import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 760
    title: "Rumour Simulation"
    color: Theme.bg

    property int activeTab: 0
    property int graphBrowserIndex: -1

    Connections {
        target: sim_controller

        function onExperiment_completed(index, success, steps) {
            if (root.graphBrowserIndex === -1) {
                root.graphBrowserIndex = index
            }
        }

        function onAll_experiments_completed() {
            progressOverlay.visible = false
            if (root.graphBrowserIndex === -1 && sim_controller.experiments_done > 0) {
                root.graphBrowserIndex = sim_controller.experiments_done - 1
            }
        }

        function onError_occurred(message) {
            errorBanner.message = message
            errorBanner.visible = true
            errorHideTimer.restart()
        }
    }

    Timer {
        id: errorHideTimer
        interval: 6000
        repeat: false
        onTriggered: {
            errorBanner.visible = false
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // LEFT SIDEBAR
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 300
            color: Theme.surface
            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: Theme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                // Title
                Item {
                    Layout.fillWidth: true
                    height: 52
                    Text {
                        text: "RUMOUR\nSIMULATOR"
                        font.pixelSize: 18
                        font.letterSpacing: 3
                        font.bold: true
                        color: Theme.txt
                        lineHeight: 1.3
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 32
                        height: 3
                        color: Theme.accent
                        radius: 2
                    }
                }

                SectionLabel { Layout.fillWidth: true; text: "SIMULATION MODE" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ModeTab {
                        Layout.fillWidth: true
                        label: "NO RETURN"
                        highlight: sim_controller.mode === 0
                        accent: Theme.accent
                        onClicked: {
                            sim_controller.mode = 0
                        }
                    }
                    ModeTab {
                        Layout.fillWidth: true
                        label: "NO REPEAT"
                        highlight: sim_controller.mode === 1
                        accent: Theme.warn
                        onClicked: {
                            sim_controller.mode = 1
                        }
                    }
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "n  — total people"
                    value: sim_controller.n
                    from: 2
                    to: 1000000
                    stepSize: 1
                    isInt: true
                    sliderColor: Theme.accent
                    onMoved: function(v) {
                        sim_controller.n = Math.round(v)
                    }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "r  — steps to survive"
                    value: sim_controller.r
                    from: 1
                    to: 1000000
                    stepSize: 1
                    isInt: true
                    sliderColor: Theme.success
                    onMoved: function(v) {
                        sim_controller.r = Math.round(v)
                    }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "N  — group size per step"
                    value: sim_controller.N
                    from: 1
                    to: 10000
                    stepSize: 1
                    isInt: true
                    sliderColor: Theme.warn
                    onMoved: function(v) {
                        sim_controller.N = Math.round(v)
                    }
                }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "K  — number of experiments"
                    value: sim_controller.K
                    from: 1
                    to: 100000000
                    stepSize: 1
                    isInt: true
                    sliderColor: Theme.danger
                    onMoved: function(v) {
                        sim_controller.K = Math.round(v)
                    }
                }

                SectionLabel { Layout.fillWidth: true; text: "BATCH MODE" }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    ModeTab {
                        Layout.fillWidth: true
                        label: "NORMAL"
                        highlight: !sim_controller.fast_mode
                        accent: Theme.accent
                        onClicked: { sim_controller.fast_mode = false }
                    }
                    ModeTab {
                        Layout.fillWidth: true
                        label: "⚡ FAST"
                        highlight: sim_controller.fast_mode
                        accent: Theme.success
                        onClicked: { sim_controller.fast_mode = true }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: sim_controller.fast_mode
                        ? "Stats only — no graph storage"
                        : "Stores graphs for browsing"
                    color: Theme.muted
                    font.pixelSize: 10
                    wrapMode: Text.Wrap
                }

                SectionLabel { Layout.fillWidth: true; text: "CONTROL" }

                AppButton {
                    Layout.fillWidth: true
                    label: "▶  Run All (" + sim_controller.K + ")"
                    accent: Theme.accent
                    enabled: !sim_controller.is_running
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: {
                        root.graphBrowserIndex = -1
                        progressOverlay.visible = true
                        sim_controller.start()
                    }
                }

                AppButton {
                    Layout.fillWidth: true
                    label: "▷  Single Experiment"
                    accent: Theme.success
                    enabled: !sim_controller.is_running && !sim_controller.fast_mode
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: {
                        root.graphBrowserIndex = -1
                        sim_controller.run_single()
                    }
                }
                AppButton {
                    Layout.fillWidth: true
                    label: "Reset"
                    accent: Theme.muted
                    enabled: !sim_controller.is_running
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: {
                        sim_controller.reset()
                        root.graphBrowserIndex = -1
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "Rumour propagation model"
                    color: Theme.muted
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }

        // RIGHT AREA
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // TOP BAR with stats + tabs
            Rectangle {
                Layout.fillWidth: true
                height: 64
                color: Theme.surface
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: Theme.border
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 0

                    // Stats row
                    Row {
                        spacing: 0

                        StatBadge {
                            label: "DONE"
                            value: sim_controller.experiments_done
                            accent: Theme.txt
                            fraction: sim_controller.K
                        }

                        StatDivider { height: 40; anchors.verticalCenter: parent.verticalCenter; leftPadding: 36; rightPadding: 36 }

                        StatBadge {
                            label: "SUCCESS"
                            value: sim_controller.success_count
                            accent: Theme.success
                            fraction: sim_controller.experiments_done
                        }

                        StatDivider { height: 40; anchors.verticalCenter: parent.verticalCenter; leftPadding: 36; rightPadding: 36 }

                        StatBadge {
                            label: "FAILURE"
                            value: sim_controller.failure_count
                            accent: Theme.danger
                            fraction: sim_controller.experiments_done
                        }

                        StatDivider { height: 40; anchors.verticalCenter: parent.verticalCenter; leftPadding: 36; rightPadding: 36 }

                        Item { width: 36; height: 1 }

                        // Probability display
                        ColumnLayout {
                            spacing: 2
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "P(SUCCESS)"
                                color: Theme.muted
                                font.pixelSize: 10
                                font.letterSpacing: 2
                                font.bold: true
                            }
                            Text {
                                text: sim_controller.success_prob.toFixed(6)
                                color: Theme.accent
                                font.pixelSize: 22
                                font.bold: true
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Tab switcher
                    Row {
                        spacing: 4
                        Repeater {
                            model: ["Results", "Graph Viewer"]
                            Rectangle {
                                width: tabText.implicitWidth + 24
                                height: 32
                                radius: 4
                                color: root.activeTab === index
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                    : "transparent"
                                border.color: root.activeTab === index ? Theme.accent : Theme.border
                                border.width: 1
                                Text {
                                    id: tabText
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: root.activeTab === index ? Theme.accent : Theme.muted
                                    font.pixelSize: 12
                                    font.bold: root.activeTab === index
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.activeTab = index
                                    }
                                }
                            }
                        }
                    }

                    // Status
                    Text {
                        leftPadding: 16
                        text: sim_controller.is_running ? "● RUNNING" : (sim_controller.experiments_done > 0 ? "● IDLE" : "○ READY")
                        color: sim_controller.is_running ? Theme.warn : (sim_controller.experiments_done > 0 ? Theme.success : Theme.muted)
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 1
                    }
                }
            }

            // Tab content
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab

                // TAB 0: Results table
                Rectangle {
                    color: Theme.bg

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 0
                        spacing: 0

                        // Table header — hidden in fast mode
                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            color: Theme.surface
                            visible: !sim_controller.fast_mode
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.border
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 0
                                Text { text: "#"; color: Theme.muted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 60 }
                                Text { text: "OUTCOME"; color: Theme.muted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 110 }
                                Text { text: "TRANSMISSIONS"; color: Theme.muted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1; Layout.fillWidth: true }
                                Text { text: "GRAPH"; color: Theme.muted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1; Layout.preferredWidth: 90; horizontalAlignment: Text.AlignHCenter }
                            }
                        }

                        // Placeholder — no experiments yet
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: sim_controller.experiments_done === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 16
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "📊"; font.pixelSize: 48 }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Run experiments to see results"
                                    color: Theme.muted
                                    font.pixelSize: 14
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Configure parameters and press ▶ Run All"
                                    color: "#3a2f60"
                                    font.pixelSize: 12
                                }
                            }
                        }

                        // Fast mode stats-only view
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: sim_controller.fast_mode && sim_controller.experiments_done > 0

                            Column {
                                anchors.centerIn: parent
                                spacing: 20

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "⚡"
                                    font.pixelSize: 48
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Fast mode — no per-experiment data stored"
                                    color: Theme.muted
                                    font.pixelSize: 14
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.min(500, fastCardCol.implicitWidth + 48)
                                    height: fastCardCol.implicitHeight + 32
                                    radius: 10
                                    color: Theme.card
                                    border.color: Theme.border
                                    border.width: 1

                                    Column {
                                        id: fastCardCol
                                        anchors.centerIn: parent
                                        spacing: 10

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "P(success) = " + sim_controller.success_prob.toFixed(6)
                                            color: Theme.accent
                                            font.pixelSize: 18
                                            font.bold: true
                                        }

                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 6
                                            Text {
                                                text: sim_controller.success_count.toLocaleString(Qt.locale(), "f", 0)
                                                color: Theme.success
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                            Text { text: "succeeded"; color: Theme.muted; font.pixelSize: 12 }
                                            Text { text: "·"; color: Theme.border; font.pixelSize: 12 }
                                            Text {
                                                text: sim_controller.failure_count.toLocaleString(Qt.locale(), "f", 0)
                                                color: Theme.danger
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                            Text { text: "failed"; color: Theme.muted; font.pixelSize: 12 }
                                            Text { text: "·"; color: Theme.border; font.pixelSize: 12 }
                                            Text { text: "total"; color: Theme.muted; font.pixelSize: 12 }
                                            Text {
                                                text: sim_controller.experiments_done.toLocaleString(Qt.locale(), "f", 0)
                                                color: Theme.txt
                                                font.pixelSize: 12
                                                font.bold: true
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Switch to Normal mode to browse individual graphs"
                                    color: "#3a2f60"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Normal mode results list
                        ListView {
                            id: resultsList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !sim_controller.fast_mode && sim_controller.experiments_done > 0
                            clip: true
                            model: sim_controller.fast_mode ? 0 : sim_controller.experiments_done
                            spacing: 0

                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { radius: 3; color: Theme.border }
                            }

                            delegate: Rectangle {
                                width: resultsList.width
                                height: 40
                                color: root.graphBrowserIndex === index
                                    ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                    : rowMa.containsMouse ? Theme.card : (index % 2 === 0 ? Theme.bg : "#130f25")
                                border.color: root.graphBrowserIndex === index ? Theme.accent : "transparent"
                                border.width: 1

                                property var expData: sim_controller ? (sim_controller.experiments_done, sim_controller.get_result_at(index)) : {}

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 0

                                    Text {
                                        text: "#" + (index + 1)
                                        color: Theme.muted
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 60
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 110
                                        height: 22
                                        radius: 4
                                        color: expData.success
                                            ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.18)
                                            : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18)
                                        border.color: expData.success ? Theme.success : Theme.danger
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: expData.success ? "✓  SUCCESS" : "✗  FAILURE"
                                            color: expData.success ? Theme.success : Theme.danger
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }

                                    Item { Layout.preferredWidth: 12 }

                                    Text {
                                        text: (expData.steps_taken !== undefined ? expData.steps_taken : 0) + " transmissions"
                                        color: Theme.txt
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 90
                                        height: 26
                                        radius: 4
                                        color: viewMa.containsMouse
                                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                                            : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                        border.color: Theme.accent
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "View Graph"
                                            color: Theme.accent
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                        MouseArea {
                                            id: viewMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.graphBrowserIndex = index
                                                root.activeTab = 1
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rowMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    z: -1
                                    onClicked: {
                                        root.graphBrowserIndex = index
                                    }
                                }
                            }
                        }
                    }
                }

                // TAB 1: Graph Viewer
                Rectangle {
                    color: Theme.bg

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Graph browser toolbar
                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            color: Theme.surface
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: Theme.border
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 10

                                Text {
                                    text: "EXPERIMENT:"
                                    color: Theme.muted
                                    font.pixelSize: 11
                                    font.letterSpacing: 2
                                }

                                // Prev button
                                Rectangle {
                                    width: 32; height: 32; radius: 4
                                    color: prevMa.containsMouse ? Theme.card : "transparent"
                                    border.color: Theme.border; border.width: 1
                                    opacity: root.graphBrowserIndex > 0 ? 1.0 : 0.3
                                    Text { anchors.centerIn: parent; text: "←"; color: Theme.txt; font.pixelSize: 14; font.bold: true }
                                    MouseArea {
                                        id: prevMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.graphBrowserIndex > 0) {
                                                root.graphBrowserIndex -= 1
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: root.graphBrowserIndex >= 0
                                        ? "#" + (root.graphBrowserIndex + 1) + " of " + sim_controller.experiments_done
                                        : "—"
                                    color: Theme.txt
                                    font.pixelSize: 13
                                    font.bold: true
                                    Layout.preferredWidth: 100
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                // Next button
                                Rectangle {
                                    width: 32; height: 32; radius: 4
                                    color: nextMa.containsMouse ? Theme.card : "transparent"
                                    border.color: Theme.border; border.width: 1
                                    opacity: root.graphBrowserIndex < sim_controller.experiments_done - 1 ? 1.0 : 0.3
                                    Text { anchors.centerIn: parent; text: "→"; color: Theme.txt; font.pixelSize: 14; font.bold: true }
                                    MouseArea {
                                        id: nextMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.graphBrowserIndex < sim_controller.experiments_done - 1) {
                                                root.graphBrowserIndex += 1
                                            }
                                        }
                                    }
                                }

                                // Jump to last
                                Rectangle {
                                    width: 80; height: 32; radius: 4
                                    color: jumpMa.containsMouse ? Theme.card : "transparent"
                                    border.color: Theme.border; border.width: 1
                                    visible: sim_controller.experiments_done > 0
                                    Text { anchors.centerIn: parent; text: "→ Last"; color: Theme.muted; font.pixelSize: 11 }
                                    MouseArea {
                                        id: jumpMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.graphBrowserIndex = sim_controller.experiments_done - 1
                                        }
                                    }
                                }

                                // Outcome badge
                                Rectangle {
                                    visible: root.graphBrowserIndex >= 0
                                    height: 28
                                    width: outcomeText.implicitWidth + 20
                                    radius: 4
                                    property var gdata: root.graphBrowserIndex >= 0 ? sim_controller.get_experiment_graph(root.graphBrowserIndex) : {}
                                    property bool isSuccess: gdata && gdata.success === true
                                    color: isSuccess
                                        ? Qt.rgba(Theme.success.r, Theme.success.g, Theme.success.b, 0.18)
                                        : Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.18)
                                    border.color: isSuccess ? Theme.success : Theme.danger
                                    border.width: 1
                                    Text {
                                        id: outcomeText
                                        anchors.centerIn: parent
                                        text: parent.isSuccess ? "✓ SUCCESS" : "✗ FAILURE"
                                        color: parent.isSuccess ? Theme.success : Theme.danger
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: root.graphBrowserIndex >= 0
                                    property var gdata: root.graphBrowserIndex >= 0 ? sim_controller.get_experiment_graph(root.graphBrowserIndex) : {}
                                    text: gdata && gdata.edges ? gdata.edges.length + " transmissions · " + (gdata.nodes ? gdata.nodes.length : 0) + " nodes reached" : ""
                                    color: Theme.muted
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Graph canvas
                        ExperimentGraphView {
                            id: expGraphView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            experimentIndex: root.graphBrowserIndex
                            colOrigin:  Theme.warn
                            colReached: Theme.success
                            colFailed:  Theme.danger
                            colBg:      Theme.bg
                            colEdge:    Theme.muted
                            colMuted:   Theme.muted
                            colTxt:     Theme.txt
                            colCard:    Theme.card
                            colBorder:  Theme.border
                            colAccent:  Theme.accent
                        }
                    }
                }
            }
        }
    }

    // Progress overlay
    Rectangle {
        id: progressOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        visible: false
        z: 500

        Rectangle {
            anchors.centerIn: parent
            width: 380
            height: overlayColumn.implicitHeight + 56
            radius: 12
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            ColumnLayout {
                id: overlayColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                spacing: 16

                Text {
                    text: "Running experiments..."
                    color: Theme.txt
                    font.pixelSize: 15
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Progress bar
                Rectangle {
                    id: progressTrack
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Theme.border

                    Rectangle {
                        width: sim_controller.K > 0
                            ? progressTrack.width * sim_controller.experiments_done / sim_controller.K
                            : 0
                        height: 8
                        radius: 4
                        color: Theme.accent
                    }
                }

                Text {
                    text: sim_controller.experiments_done + " / " + sim_controller.K
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.alignment: Qt.AlignHCenter
                }

                AppButton {
                    Layout.fillWidth: true
                    label: "⏹  Stop"
                    accent: Theme.danger
                    onClicked: {
                        sim_controller.stop()
                        progressOverlay.visible = false
                    }
                }
            }
        }
    }

    // Error banner
    Rectangle {
        id: errorBanner
        property string message: ""
        visible: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: visible ? 24 : -60
        width: Math.min(errMsg.implicitWidth + 56, parent.width - 48)
        height: 52
        radius: 10
        color: "#1a0a0a"
        border.color: Theme.danger
        border.width: 1
        z: 1000

        Row {
            anchors.centerIn: parent
            spacing: 12
            Text { text: "⚠"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: errMsg
                text: errorBanner.message
                color: "#fca5a5"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.NoWrap
            }
        }
    }
}
