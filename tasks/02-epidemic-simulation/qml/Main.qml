import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".";

ApplicationWindow {
    id: root
    visible: true
    width: 1100
    height: 720
    title: "Infection Simulation"
    color: "#0a0e1a"


    property bool simLoaded:   false
    property bool autoRunning: false
    property int  tps: 5
    property int  fps: 30
    property int  searchMode: 0
    property int  activeTab: 0   // 0 = Stats/Search, 1 = Graph

    property int totalCount: sim_controller.healthy_count
                           + sim_controller.infected_count
                           + sim_controller.recovered_count

    // step timer (TPS)
    Timer {
        id: stepTimer
        interval: Math.round(1000 / root.tps)
        repeat: true
        running: root.autoRunning && root.simLoaded
        onTriggered: sim_controller.step()
    }

    // render timer (FPS)
    Timer {
        id: graphRefreshTimer
        interval: Math.round(1000 / root.fps)
        repeat: true
        running: root.autoRunning && root.simLoaded && root.activeTab === 1
        onTriggered: graphView.updateStates(sim_controller.get_node_states())
    }

    //  search results model
    ListModel { id: searchResultModel }

    Connections {
        target: sim_controller
        function onSearch_results_ready(ids) {
            searchResultModel.clear()
            for (var i = 0; i < ids.length; i++)
                searchResultModel.append({ "nodeId": ids[i] })
        }
        function onSimulation_updated() {
            var total = sim_controller.healthy_count
                      + sim_controller.infected_count
                      + sim_controller.recovered_count
            if (!root.simLoaded && total > 0) {
                root.simLoaded = true
                root.searchMode = 0
                // totalNodes set via property binding in GraphView
            }
        }
        function onLoad_failed(reason) {
            errorBanner.message = reason
            errorBanner.visible = true
            errorHideTimer.restart()
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        //  LEFT SIDEBAR
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 290
            color: Theme.surface
            Rectangle { anchors.right: parent.right; width: 1; height: parent.height; color: Theme.border }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                // Title
                Item {
                    Layout.fillWidth: true
                    height: 52
                    Text {
                        text: "INFECTION\nSIMULATOR"
                        font.pixelSize: 18; font.letterSpacing: 3; font.bold: true
                        color: Theme.txt; lineHeight: 1.3
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: 32; height: 3; color: Theme.accent; radius: 2 }
                }

                SectionLabel { Layout.fillWidth: true; text: "DATA SOURCE" }

                AppButton {
                    Layout.fillWidth: true
                    label: "Load Graph File"; icon: "📂"; accent: Theme.accent
                    onClicked: fileDialog.open()
                }
                Text {
                    id: fileLabel
                    text: "No file loaded"
                    color: Theme.muted; font.pixelSize: 11; wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }

                SectionLabel { Layout.fillWidth: true; text: "PARAMETERS" }

                ParamSlider {
                    Layout.fillWidth: true
                    label: "p₁  Infection prob."
                    value: 0.3; from: 0.0; to: 1.0; stepSize: 0.01
                    sliderColor: Theme.danger
                    onMoved: function(v) { sim_controller.set_infection_prob(v) }
                }
                ParamSlider {
                    Layout.fillWidth: true
                    label: "p₂  Recovery prob."
                    value: 0.1; from: 0.0; to: 1.0; stepSize: 0.01
                    sliderColor: Theme.success
                    onMoved: function(v) { sim_controller.set_recovery_prob(v) }
                }

                SectionLabel { Layout.fillWidth: true; text: "SIMULATION MODE" }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    ModeTab { Layout.fillWidth: true; label: "MANUAL"; highlight: !root.autoRunning; accent: Theme.accent; onClicked: root.autoRunning = false }
                    ModeTab { Layout.fillWidth: true; label: "AUTO";   highlight: root.autoRunning;  accent: Theme.warn;   onClicked: if (root.simLoaded) root.autoRunning = true }
                }

                AppButton {
                    Layout.fillWidth: true; label: "Step  →"; accent: Theme.accent
                    enabled: root.simLoaded && !root.autoRunning
                    opacity: enabled ? 1.0 : 0.4
                    onClicked: sim_controller.step()
                }

                ColumnLayout {
                    Layout.fillWidth: true; spacing: 10
                    opacity: root.autoRunning ? 1.0 : 0.4
                    ParamSlider {
                        Layout.fillWidth: true
                        label: "TPS (logic)  " + root.tps
                        value: root.tps; from: 1; to: 30; stepSize: 1
                        sliderColor: Theme.warn
                        onMoved: function(v) { root.tps = Math.round(v) }
                    }
                    ParamSlider {
                        Layout.fillWidth: true
                        label: "FPS (render)  " + root.fps
                        value: root.fps; from: 1; to: 60; stepSize: 1
                        sliderColor: Theme.accent
                        onMoved: function(v) { root.fps = Math.round(v) }
                    }
                    AppButton {
                        Layout.fillWidth: true
                        label: root.autoRunning ? "⏹  Stop" : "▶  Start"
                        accent: Theme.warn
                        onClicked: root.autoRunning = !root.autoRunning
                    }
                }

                AppButton {
                    Layout.fillWidth: true; label: "Reset"; accent: Theme.muted
                    enabled: root.simLoaded; opacity: enabled ? 1.0 : 0.4
                    onClicked: { root.autoRunning = false; sim_controller.reset(); root.searchMode = 0 }
                }

                Item { Layout.fillHeight: true }

                Text { text: "SIR model"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 1 }
            }
        }

        //  RIGHT AREA
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            //  Stats bar
            Rectangle {
                Layout.fillWidth: true; height: 80; color: Theme.card
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24; anchors.rightMargin: 24; spacing: 20

                    StatBadge { Layout.fillWidth: true; label: "HEALTHY";   value: sim_controller.healthy_count;   accent: Theme.success; fraction: root.totalCount }
                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12 }
                    StatBadge { Layout.fillWidth: true; label: "INFECTED";  value: sim_controller.infected_count;  accent: Theme.danger;  fraction: root.totalCount }
                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12 }
                    StatBadge { Layout.fillWidth: true; label: "RECOVERED"; value: sim_controller.recovered_count; accent: Theme.accent;  fraction: root.totalCount }
                    StatDivider { Layout.fillHeight: true; Layout.topMargin: 12; Layout.bottomMargin: 12 }
                    StatBadge { Layout.fillWidth: true; label: "TOTAL";     value: root.totalCount;                accent: Theme.muted;   fraction: 0 }

                    Item { Layout.fillWidth: true }

                    Column {
                        spacing: 6
                        Text { text: "SPREAD"; color: Theme.muted; font.pixelSize: 10; font.letterSpacing: 2 }
                        Rectangle {
                            width: 180; height: 8; radius: 4; color: Theme.border
                            Rectangle {
                                width: root.totalCount > 0
                                    ? parent.width * (sim_controller.infected_count + sim_controller.recovered_count) / root.totalCount
                                    : 0
                                height: parent.height; radius: 4
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.warn }
                                    GradientStop { position: 1.0; color: Theme.danger }
                                }
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }
                        Text {
                            text: root.totalCount > 0
                                ? Math.round((sim_controller.infected_count + sim_controller.recovered_count) * 100 / root.totalCount) + "% affected"
                                : "—"
                            color: Theme.muted; font.pixelSize: 10
                        }
                    }
                }
            }

            // Tab bar
            Rectangle {
                Layout.fillWidth: true; height: 44; color: Theme.surface
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 0

                    // Tab buttons
                    Repeater {
                        model: ["📋  Statistics & Search", "🕸️  Graph View"]
                        Rectangle {
                            height: parent.height
                            width: tabLabel.implicitWidth + 32
                            color: "transparent"
                            // active indicator
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width; height: 2
                                color: root.activeTab === index ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: root.activeTab === index ? Theme.txt : Theme.muted
                                font.pixelSize: 13
                                font.bold: root.activeTab === index
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = index
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Status indicator
                    Text {
                        text: root.simLoaded
                            ? (root.autoRunning ? "● AUTO  " + root.tps + " TPS" : "● MANUAL")
                            : "○ NOT LOADED"
                        color: root.simLoaded ? (root.autoRunning ? Theme.warn : Theme.accent) : Theme.muted
                        font.pixelSize: 11; font.bold: true; font.letterSpacing: 1
                    }
                }
            }

            // Tab content
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.activeTab
                onCurrentIndexChanged: {
                    if (currentIndex === 1 && root.simLoaded)
                        graphView.updateStates(sim_controller.get_node_states())
                }

                // TAB 0: Stats & Search
                ColumnLayout {
                    spacing: 0

                    // Search toolbar
                    Rectangle {
                        Layout.fillWidth: true; height: 52; color: Theme.surface
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8
                            Text { text: "SEARCH:"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 2 }
                            SearchButton { label: "All Healthy";          mode: 1; currentMode: root.searchMode; accent: Theme.success; onClicked: { root.searchMode = 1; sim_controller.search_healthy() } }
                            SearchButton { label: "All Recovered";        mode: 2; currentMode: root.searchMode; accent: Theme.accent;  onClicked: { root.searchMode = 2; sim_controller.search_recovered() } }
                            SearchButton { label: "Recovered (lonely)";   mode: 3; currentMode: root.searchMode; accent: Theme.warn;    onClicked: { root.searchMode = 3; sim_controller.search_recovered_lonely() } }
                            SearchButton { label: "Healthy (surrounded)"; mode: 4; currentMode: root.searchMode; accent: Theme.danger;  onClicked: { root.searchMode = 4; sim_controller.search_healthy_surrounded() } }
                            SearchButton { label: "Clear";                mode: 0; currentMode: root.searchMode; accent: Theme.muted;   onClicked: { root.searchMode = 0; sim_controller.clear_search() } }
                            Item { Layout.fillWidth: true }
                        }
                    }

                    // Results area
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.bg

                        // Placeholder
                        Column {
                            anchors.centerIn: parent; spacing: 16
                            visible: root.searchMode === 0 || !root.simLoaded
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.simLoaded ? "🔍" : "📊"; font.pixelSize: 48 }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.simLoaded ? "Use search buttons above to query simulation results" : "Load a graph file to begin simulation"
                                color: Theme.muted; font.pixelSize: 14
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.simLoaded ? "Run a few steps first, then search" : "Expected format: edge list (u v per line)"
                                color: "#3a4a65"; font.pixelSize: 12
                            }
                        }

                        // Results
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 12
                            visible: root.searchMode !== 0 && root.simLoaded

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: { switch(root.searchMode) {
                                        case 1: return "All Healthy People"
                                        case 2: return "All Recovered People"
                                        case 3: return "Recovered — Surrounded by Non-Recovered"
                                        case 4: return "Healthy — All Neighbours Infected"
                                        default: return ""
                                    }}
                                    color: Theme.txt; font.pixelSize: 16; font.bold: true
                                }
                                Item { Layout.fillWidth: true }
                                Text { text: searchResultModel.count + " results"; color: Theme.muted; font.pixelSize: 12 }
                            }

                            GridView {
                                Layout.fillWidth: true; Layout.fillHeight: true
                                model: searchResultModel; cellWidth: 90; cellHeight: 56; clip: true
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                                delegate: Rectangle {
                                    width: 84; height: 50; radius: 6; color: Theme.card; border.width: 1
                                    border.color: { switch(root.searchMode) {
                                        case 1: return Theme.success; case 2: return Theme.accent
                                        case 3: return Theme.warn;    case 4: return Theme.danger
                                        default: return Theme.border
                                    }}
                                    Text { anchors.centerIn: parent; text: "ID " + model.nodeId; color: Theme.txt; font.pixelSize: 12; font.bold: true }
                                }
                            }
                        }
                    }
                }

                // TAB 1: Graph View
                GraphView {
                    id: graphView
                    simLoaded: root.simLoaded
                    colHealthy:   Theme.success
                    colInfected:  Theme.danger
                    colRecovered: Theme.accent
                    colBg:        Theme.bg
                    colEdge:      Theme.border
                    colMuted:     Theme.muted
                    colTxt:       Theme.txt
                    colBorder:    Theme.border
                }
            }
        }
    }

    // file dialog + error banner
    Timer {
        id: errorHideTimer
        interval: 6000
        repeat: false
        onTriggered: errorBanner.visible = false
    }

    Rectangle {
        id: errorBanner
        property string message: ""
        visible: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: visible ? 24 : -60
        width: Math.min(errorMsg.implicitWidth + 56, parent.width - 48)
        height: 52
        radius: 10
        color: "#1a0a0a"
        border.color: Theme.danger; border.width: 1
        z: 100
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity    { NumberAnimation { duration: 200 } }

        Row {
            anchors.centerIn: parent; spacing: 12
            Text { text: "⚠"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
            Text {
                id: errorMsg
                text: errorBanner.message
                color: "#fca5a5"; font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                wrapMode: Text.NoWrap
            }
        }
    }

    FilePickerDialog {
        id: fileDialog
        onAccepted: function(path) {
            fileLabel.text = path.split("/").pop()
            root.simLoaded = false
            root.autoRunning = false
            sim_controller.load_graph(path)
        }
    }
}
