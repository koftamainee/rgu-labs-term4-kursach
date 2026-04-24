import QtQuick
import "."

Item {
    id: graphView

    property int experimentIndex: -1
    property color colOrigin:  "#fbbf24"
    property color colReached: "#34d399"
    property color colFailed:  "#f87171"
    property color colBg:      "#0f0c1f"
    property color colEdge:    "#a5a1b8"
    property color colMuted:   "#a5a1b8"
    property color colTxt:     "#e0d9ff"
    property color colCard:    "#2a244a"
    property color colBorder:  "#3a2f60"
    property color colAccent:  "#8b5cf6"

    onExperimentIndexChanged: {
        internal.loadExperiment(experimentIndex)
    }

    QtObject {
        id: internal

        property var nodes: []
        property var edgeIndices: []
        property var nodePos: []
        property var nodeVel: []
        property var nodeSteps: []

        // animation state
        property int  animIter:    0
        property int  totalIters:  150
        property int  itersPerTick: 3
        property real layoutK:     1.0
        property real layoutTemp:  0.05
        property real layoutCool:  0.88

        function loadExperiment(idx) {
            layoutTimer.stop()
            animIter = 0

            if (idx < 0) {
                nodes = []
                edgeIndices = []
                nodePos = []
                nodeVel = []
                nodeSteps = []
                canvas.requestPaint()
                return
            }

            var data = sim_controller.get_experiment_graph(idx)
            if (!data || !data.nodes) {
                nodes = []
                edgeIndices = []
                nodePos = []
                nodeVel = []
                nodeSteps = []
                canvas.requestPaint()
                return
            }

            var rawNodes = data.nodes
            var rawEdges = data.edges

            var idxMap = {}
            nodes = []
            nodeSteps = []

            for (var i = 0; i < rawNodes.length; i++) {
                idxMap[rawNodes[i]] = i
                nodes.push({ id: rawNodes[i] })
                nodeSteps.push(99999)
            }

            edgeIndices = []
            for (var e = 0; e < rawEdges.length; e++) {
                var ai = idxMap[rawEdges[e].from]
                var bi = idxMap[rawEdges[e].to]
                if (ai !== undefined && bi !== undefined) {
                    edgeIndices.push({ ai: ai, bi: bi, step: rawEdges[e].step })
                    if (rawEdges[e].step < nodeSteps[bi]) {
                        nodeSteps[bi] = rawEdges[e].step
                    }
                }
            }
            if (idxMap[0] !== undefined) {
                nodeSteps[idxMap[0]] = -1
            }

            initPositions()

            var n = nodes.length
            layoutK    = Math.sqrt(0.4 / Math.max(n, 1))
            layoutTemp = 0.1
            animIter   = 0

            if (n <= 3) {
                runAllLayout()
                canvas.requestPaint()
            } else {
                canvas.requestPaint()
                layoutTimer.start()
            }
        }

        function initPositions() {
            var n = nodes.length
            nodePos = []
            nodeVel = []
            for (var i = 0; i < n; i++) {
                var angle = (2 * Math.PI * i) / n
                nodePos.push({ x: 0.5 + 0.22 * Math.cos(angle), y: 0.5 + 0.22 * Math.sin(angle) })
                nodeVel.push({ vx: 0, vy: 0 })
            }
        }

        function runIterations(count) {
            var n = nodes.length
            if (n === 0) { return }
            var k       = layoutK
            var repStep = n > 300 ? 3 : 1

            for (var iter = 0; iter < count; iter++) {
                // repulsion
                for (var i = 0; i < n; i++) {
                    var fx = 0
                    var fy = 0
                    for (var j = 0; j < n; j += repStep) {
                        if (i === j) { continue }
                        var dx   = nodePos[i].x - nodePos[j].x
                        var dy   = nodePos[i].y - nodePos[j].y
                        var dist = Math.sqrt(dx * dx + dy * dy) + 0.0001
                        var rep  = (k * k) / dist
                        fx += (dx / dist) * rep
                        fy += (dy / dist) * rep
                    }
                    nodeVel[i].vx = (nodeVel[i].vx + fx) * 0.25
                    nodeVel[i].vy = (nodeVel[i].vy + fy) * 0.25
                }
                for (var e = 0; e < edgeIndices.length; e++) {
                    var ai  = edgeIndices[e].ai
                    var bi  = edgeIndices[e].bi
                    var ex  = nodePos[ai].x - nodePos[bi].x
                    var ey  = nodePos[ai].y - nodePos[bi].y
                    var ed  = Math.sqrt(ex * ex + ey * ey) + 0.0001
                    var att = (ed * ed) / k
                    var fax = (ex / ed) * att * 0.5
                    var fay = (ey / ed) * att * 0.5
                    nodeVel[ai].vx -= fax
                    nodeVel[ai].vy -= fay
                    nodeVel[bi].vx += fax
                    nodeVel[bi].vy += fay
                }
                // move
                for (var vi = 0; vi < n; vi++) {
                    var vmag  = Math.sqrt(nodeVel[vi].vx * nodeVel[vi].vx + nodeVel[vi].vy * nodeVel[vi].vy) + 0.0001
                    var scale = Math.min(vmag, layoutTemp) / vmag
                    nodePos[vi].x = Math.max(0.04, Math.min(0.96, nodePos[vi].x + nodeVel[vi].vx * scale))
                    nodePos[vi].y = Math.max(0.04, Math.min(0.96, nodePos[vi].y + nodeVel[vi].vy * scale))
                }
                layoutTemp *= layoutCool
                animIter++
            }
        }

        function runAllLayout() {
            var remaining = totalIters - animIter
            if (remaining > 0) {
                runIterations(remaining)
            }
        }
    }

    Timer {
        id: layoutTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: {
            if (internal.animIter >= internal.totalIters) {
                stop()
                return
            }
            internal.runIterations(internal.itersPerTick)
            canvas.requestPaint()
        }
    }

    property real viewScale: 1.0
    property real viewOffX: 0.0
    property real viewOffY: 0.0

    onWidthChanged:  { canvas.requestPaint() }
    onHeightChanged: { canvas.requestPaint() }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            var W = width
            var H = height
            ctx.clearRect(0, 0, W, H)
            ctx.fillStyle = graphView.colBg
            ctx.fillRect(0, 0, W, H)

            var nodes = internal.nodes
            var edges = internal.edgeIndices
            var pos   = internal.nodePos
            var steps = internal.nodeSteps

            if (nodes.length === 0) { return }

            var sc = graphView.viewScale
            var ox = graphView.viewOffX
            var oy = graphView.viewOffY
            var nr = Math.max(10, 10 * sc)

            // animation progress [0..1] for fade-in effect
            var progress = internal.totalIters > 0
                ? Math.min(1.0, internal.animIter / internal.totalIters)
                : 1.0

            function px(nx) { return ox + nx * W * sc }
            function py(ny) { return oy + ny * H * sc }

            // draw edges — fade in as layout settles
            ctx.lineWidth = Math.max(2, 2.5 * sc)
            for (var e = 0; e < edges.length; e++) {
                var ai = edges[e].ai
                var bi = edges[e].bi
                var x1 = px(pos[ai].x)
                var y1 = py(pos[ai].y)
                var x2 = px(pos[bi].x)
                var y2 = py(pos[bi].y)
                var angle    = Math.atan2(y2 - y1, x2 - x1)
                var arrowLen = Math.max(6, nr * 1.2)
                var ex2      = x2 - Math.cos(angle) * nr
                var ey2      = y2 - Math.sin(angle) * nr

                ctx.globalAlpha = progress
                ctx.strokeStyle = graphView.colEdge
                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(ex2, ey2)
                ctx.stroke()

                ctx.fillStyle = graphView.colEdge
                ctx.beginPath()
                ctx.moveTo(ex2, ey2)
                ctx.lineTo(ex2 - Math.cos(angle - 0.4) * arrowLen, ey2 - Math.sin(angle - 0.4) * arrowLen)
                ctx.lineTo(ex2 - Math.cos(angle + 0.4) * arrowLen, ey2 - Math.sin(angle + 0.4) * arrowLen)
                ctx.closePath()
                ctx.fill()
            }

            ctx.globalAlpha = 1.0

            // draw nodes
            for (var i = 0; i < nodes.length; i++) {
                var nx     = px(pos[i].x)
                var ny     = py(pos[i].y)
                var nodeId = nodes[i].id
                var step   = steps[i]

                var col
                if (nodeId === 0) {
                    col = graphView.colOrigin
                } else if (step === 99999) {
                    col = graphView.colFailed
                } else {
                    col = graphView.colReached
                }

                // glow for origin
                if (nodeId === 0) {
                    ctx.globalAlpha = 0.15 * progress
                    ctx.beginPath()
                    ctx.arc(nx, ny, nr * 2.8, 0, 2 * Math.PI)
                    ctx.fillStyle = graphView.colOrigin
                    ctx.fill()
                    ctx.globalAlpha = 1.0
                }

                ctx.beginPath()
                ctx.arc(nx, ny, nr, 0, 2 * Math.PI)
                ctx.fillStyle = col
                ctx.fill()

                // turn label
                ctx.fillStyle = "#0f0c1f"
                ctx.font = "bold " + Math.round(nr * 0.75) + "px sans-serif"
                ctx.textAlign = "center"
                ctx.textBaseline = "middle"
                var turnLabel = nodeId === 0 ? "0" : (step !== 99999 ? String(step + 1) : "?")
                ctx.fillText(turnLabel, nx, ny)
            }

            // settling indicator while animating
            if (internal.animIter < internal.totalIters) {
                ctx.globalAlpha = 0.6
                ctx.fillStyle = graphView.colMuted
                ctx.font = "11px sans-serif"
                ctx.textAlign = "right"
                ctx.textBaseline = "top"
                ctx.fillText("settling…  " + Math.round(progress * 100) + "%", W - 16, 16)
                ctx.globalAlpha = 1.0
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        property real lastX: 0
        property real lastY: 0

        onPressed: function(m) {
            // clicking while animating skips to the end
            if (layoutTimer.running) {
                layoutTimer.stop()
                internal.runAllLayout()
            }
            lastX = m.x
            lastY = m.y
        }
        onPositionChanged: function(m) {
            graphView.viewOffX += m.x - lastX
            graphView.viewOffY += m.y - lastY
            lastX = m.x
            lastY = m.y
            canvas.requestPaint()
        }
        onWheel: function(w) {
            if (layoutTimer.running) {
                layoutTimer.stop()
                internal.runAllLayout()
            }
            var f  = w.angleDelta.y > 0 ? 1.15 : 0.87
            var ns = Math.max(0.1, Math.min(12.0, graphView.viewScale * f))
            graphView.viewOffX = w.x - (w.x - graphView.viewOffX) * (ns / graphView.viewScale)
            graphView.viewOffY = w.y - (w.y - graphView.viewOffY) * (ns / graphView.viewScale)
            graphView.viewScale = ns
            canvas.requestPaint()
        }
        cursorShape: layoutTimer.running ? Qt.BusyCursor : Qt.OpenHandCursor
    }

    // Zoom controls
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: zoomRow.implicitWidth + 24
        height: 48
        color: Qt.rgba(0.07, 0.05, 0.12, 0.92)
        radius: 8
        border.color: graphView.colBorder
        border.width: 1

        Row {
            id: zoomRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: [
                    { lbl: "+", act: function() { if (layoutTimer.running) { layoutTimer.stop(); internal.runAllLayout() } graphView.viewScale = Math.min(12, graphView.viewScale * 1.25); canvas.requestPaint() } },
                    { lbl: "−", act: function() { if (layoutTimer.running) { layoutTimer.stop(); internal.runAllLayout() } graphView.viewScale = Math.max(0.1, graphView.viewScale * 0.8);  canvas.requestPaint() } },
                    { lbl: "⌂", act: function() { if (layoutTimer.running) { layoutTimer.stop(); internal.runAllLayout() } graphView.viewScale = 1; graphView.viewOffX = 0; graphView.viewOffY = 0; canvas.requestPaint() } }
                ]

                Rectangle {
                    width: 32; height: 32; radius: 4
                    color: zMa.containsMouse ? Theme.card : "transparent"
                    border.color: graphView.colBorder; border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: modelData.lbl
                        color: graphView.colTxt
                        font.pixelSize: 16
                        font.bold: true
                    }
                    MouseArea {
                        id: zMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { modelData.act() }
                    }
                }
            }
        }
    }

    // Legend
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        width: 150
        height: 86
        color: Qt.rgba(0.07, 0.05, 0.12, 0.92)
        radius: 8
        border.color: graphView.colBorder
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 10
            Repeater {
                model: [
                    { col: graphView.colOrigin,  lbl: "Origin (node 0)" },
                    { col: graphView.colReached, lbl: "Reached" },
                    { col: graphView.colEdge,    lbl: "Transmission" }
                ]
                Row {
                    spacing: 8
                    Rectangle {
                        width: 10; height: 10; radius: 5
                        color: modelData.col
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.lbl
                        color: graphView.colTxt
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    // Placeholder when no experiment selected
    Column {
        anchors.centerIn: parent
        spacing: 14
        visible: experimentIndex < 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "🕸️"
            font.pixelSize: 52
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Select an experiment to view its graph"
            color: graphView.colMuted
            font.pixelSize: 14
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Pan: drag  ·  Zoom: scroll or buttons"
            color: "#3a2f60"
            font.pixelSize: 11
        }
    }
}
