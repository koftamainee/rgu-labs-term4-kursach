import QtQuick

Item {
    id: graphView

    property bool simLoaded: false
    property color colHealthy:   "#10b981"
    property color colInfected:  "#ef4444"
    property color colRecovered: "#3b82f6"
    property color colBg:        "#0a0e1a"
    property color colEdge:      "#1e3050"
    property color colMuted:     "#64748b"
    property color colTxt:       "#e2e8f0"
    property color colCard:      "#1a2235"
    property color colBorder:    "#2a3a55"
    property color colAccent:    "#3b82f6"
    property color colWarn:      "#f59e0b"

    property real edgeVisibleScale: 0.35
    property real glowVisibleScale: 0.6

    property real viewScale: 1.0
    property real viewOffX:  0.0
    property real viewOffY:  0.0

    function loadGraph() {
        internal.fetchAndBuild(100000)
    }

    function updateStates(nodes) {
        if (!nodes || nodes.length === 0) return
        var lookup = {}
        for (var i = 0; i < nodes.length; i++)
            lookup[nodes[i].id] = nodes[i].state
        for (var j = 0; j < internal.subNodes.length; j++) {
            var nd = internal.subNodes[j]
            if (lookup[nd.id] !== undefined)
                nd.state = lookup[nd.id]
        }
        canvas.requestPaint()
    }

    onSimLoadedChanged: {
        if (simLoaded) {
            internal.totalNodes = sim_controller.healthy_count
                + sim_controller.infected_count
                + sim_controller.recovered_count
            loadGraph()
        }
    }

    Connections {
        target: sim_controller
        function onSimulation_updated() {
            if (graphView.simLoaded)
                graphView.updateStates(sim_controller.get_node_states())
        }
        function onStats_changed() {
            if (graphView.simLoaded)
                graphView.updateStates(sim_controller.get_node_states())
        }
    }

    // ── Internal state ──────────────────────────────────────────────────────
    QtObject {
        id: internal

        property var subNodes: []
        property var subEdgeIndices: []
        property var nodePos: []
        property var nodeVel: []
        property int totalNodes: 0

        function fetchAndBuild(n) {
            var sub   = sim_controller.get_bfs_subgraph(n)
            var nodes = sub["nodes"]
            var edges = sub["edges"]

            subNodes = []
            for (var i = 0; i < nodes.length; i++)
                subNodes.push({ id: nodes[i].id, state: nodes[i].state })

            var idxMap = {}
            for (var j = 0; j < subNodes.length; j++)
                idxMap[subNodes[j].id] = j

            subEdgeIndices = []
            for (var e = 0; e < edges.length; e++) {
                var ai = idxMap[edges[e].a]
                var bi = idxMap[edges[e].b]
                if (ai !== undefined && bi !== undefined)
                    subEdgeIndices.push({ ai: ai, bi: bi })
            }

            initPositions()
            runLayout()
            canvas.requestPaint()
            statusText.text = totalNodes + " nodes total  ·  showing "
                + subNodes.length + " nodes, " + subEdgeIndices.length + " edges"
        }

        function initPositions() {
            nodePos = []; nodeVel = []
            var n = subNodes.length
            for (var i = 0; i < n; i++) {
                var angle = (2 * Math.PI * i) / n
                nodePos.push({ x: 0.5 + 0.35 * Math.cos(angle),
                                y: 0.5 + 0.35 * Math.sin(angle) })
                nodeVel.push({ vx: 0, vy: 0 })
            }
        }

        property real theta: 0.9

        function buildQuadtree(positions) {
            var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9
            for (var i = 0; i < positions.length; i++) {
                if (positions[i].x < minX) minX = positions[i].x
                if (positions[i].y < minY) minY = positions[i].y
                if (positions[i].x > maxX) maxX = positions[i].x
                if (positions[i].y > maxY) maxY = positions[i].y
            }
            var hw = Math.max((maxX - minX), (maxY - minY)) / 2 + 0.01
            var cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
            var root = mkNode(cx, cy, hw)
            for (var j = 0; j < positions.length; j++)
                qtInsert(root, j, positions[j].x, positions[j].y)
            return root
        }

        function mkNode(cx, cy, hw) {
            return { cx: cx, cy: cy, hw: hw, mass: 0, cmx: 0, cmy: 0,
                     ch: null, leafIdx: -1 }
        }

        function qtInsert(node, idx, x, y) {
            if (node.mass === 0) {
                node.mass = 1; node.cmx = x; node.cmy = y; node.leafIdx = idx
                return
            }
            node.cmx = (node.cmx * node.mass + x) / (node.mass + 1)
            node.cmy = (node.cmy * node.mass + y) / (node.mass + 1)
            node.mass++

            if (node.ch === null) {
                node.ch = [null, null, null, null]
                if (node.leafIdx >= 0) {
                    var ei = node.leafIdx
                    var q0 = qtQ(node, nodePos[ei].x, nodePos[ei].y)
                    if (!node.ch[q0]) node.ch[q0] = qtChild(node, q0)
                    qtInsert(node.ch[q0], ei, nodePos[ei].x, nodePos[ei].y)
                    node.leafIdx = -1
                }
            }
            var q = qtQ(node, x, y)
            if (!node.ch[q]) node.ch[q] = qtChild(node, q)
            qtInsert(node.ch[q], idx, x, y)
        }

        function qtQ(node, x, y) {
            return (x >= node.cx ? 1 : 0) + (y >= node.cy ? 2 : 0)
        }

        function qtChild(p, q) {
            var hw = p.hw / 2
            return mkNode(p.cx + ((q & 1) ? hw : -hw),
                          p.cy + ((q & 2) ? hw : -hw), hw)
        }

        function qtForce(node, ix, iy, fRef, k) {
            if (!node || node.mass === 0) return
            var dx = ix - node.cmx
            var dy = iy - node.cmy
            var d2 = dx*dx + dy*dy
            if (d2 < 1e-10) return
            if (node.ch === null || (node.hw * 2) * (node.hw * 2) / d2 < theta * theta) {
                var d   = Math.sqrt(d2)
                var rep = (k * k * node.mass) / d
                fRef[0] += dx / d * rep
                fRef[1] += dy / d * rep
                return
            }
            for (var c = 0; c < 4; c++)
                if (node.ch[c]) qtForce(node.ch[c], ix, iy, fRef, k)
        }

        function nodeBaseRadius(n) {
            if (n > 3000) return 1.2
            if (n > 2000) return 1.8
            if (n > 1000) return 2.5
            if (n >  500) return 3.5
            if (n >  200) return 5.0
            return 7.0
        }

        function layoutSpacingScale(n) {
            if (n > 3000) return 0.55
            if (n > 2000) return 0.65
            if (n > 1000) return 0.75
            if (n >  500) return 0.85
            if (n >  200) return 0.95
            return 1.0
        }

        function runLayout() {
            var n    = subNodes.length
            if (n === 0) return
            var spacing = layoutSpacingScale(n)
            var k    = Math.sqrt(1.0 / n) * spacing
            var temp = 0.1
            var cool = 0.96
            var iters = n > 1000 ? 60 : n > 300 ? 90 : 120
            var fRef  = [0, 0]

            for (var iter = 0; iter < iters; iter++) {
                var qt = buildQuadtree(nodePos)

                // Repulsion (Barnes-Hut)
                for (var i = 0; i < n; i++) {
                    fRef[0] = 0; fRef[1] = 0
                    qtForce(qt, nodePos[i].x, nodePos[i].y, fRef, k)
                    nodeVel[i].vx = (nodeVel[i].vx + fRef[0]) * 0.5
                    nodeVel[i].vy = (nodeVel[i].vy + fRef[1]) * 0.5
                }

                // Attraction along edges
                for (var e = 0; e < subEdgeIndices.length; e++) {
                    var ai = subEdgeIndices[e].ai, bi = subEdgeIndices[e].bi
                    var ex = nodePos[ai].x - nodePos[bi].x
                    var ey = nodePos[ai].y - nodePos[bi].y
                    var ed = Math.sqrt(ex*ex + ey*ey) + 0.0001
                    var att = (ed * ed) / k
                    var fax = (ex / ed) * att * 0.5
                    var fay = (ey / ed) * att * 0.5
                    nodeVel[ai].vx -= fax; nodeVel[ai].vy -= fay
                    nodeVel[bi].vx += fax; nodeVel[bi].vy += fay
                }

                // Integrate
                for (var vi = 0; vi < n; vi++) {
                    var vm = Math.sqrt(nodeVel[vi].vx*nodeVel[vi].vx
                                     + nodeVel[vi].vy*nodeVel[vi].vy) + 0.0001
                    var sc = Math.min(vm, temp) / vm
                    nodePos[vi].x += nodeVel[vi].vx * sc
                    nodePos[vi].y += nodeVel[vi].vy * sc
                }
                temp *= cool
            }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx  = getContext("2d")
            var W = width, H = height
            ctx.clearRect(0, 0, W, H)
            ctx.fillStyle = graphView.colBg
            ctx.fillRect(0, 0, W, H)

            var nodes = internal.subNodes
            var edges = internal.subEdgeIndices
            var pos   = internal.nodePos
            if (nodes.length === 0) return

            var sc  = graphView.viewScale
            var ox  = graphView.viewOffX
            var oy  = graphView.viewOffY
            var baseR = internal.nodeBaseRadius(nodes.length)
            var nr  = Math.max(1, baseR * sc)

            var vpX0 = -ox / (W * sc),      vpY0 = -oy / (H * sc)
            var vpX1 = (W - ox) / (W * sc), vpY1 = (H - oy) / (H * sc)
            var mg   = nr * 3 / (W * sc)
            vpX0 -= mg; vpY0 -= mg; vpX1 += mg; vpY1 += mg

            function px(nx) { return ox + nx * W * sc }
            function py(ny) { return oy + ny * H * sc }
            function inView(x, y) {
                return x >= vpX0 && x <= vpX1 && y >= vpY0 && y <= vpY1
            }

            if (sc >= graphView.edgeVisibleScale) {
                var eAlpha = Math.min(1.0, (sc - graphView.edgeVisibleScale) / 0.25) * 0.45
                ctx.strokeStyle = graphView.colEdge
                ctx.lineWidth   = Math.max(0.3, 0.6 * sc)
                ctx.globalAlpha = eAlpha

                var minPx2 = 1.0

                ctx.beginPath()
                for (var e = 0; e < edges.length; e++) {
                    var ai = edges[e].ai, bi = edges[e].bi
                    var ax = pos[ai].x, ay = pos[ai].y
                    var bx = pos[bi].x, by = pos[bi].y
                    // Skip if both endpoints off-screen
                    if (!inView(ax, ay) && !inView(bx, by)) continue
                    // Skip sub-pixel edges
                    var sdx = (ax - bx) * W * sc, sdy = (ay - by) * H * sc
                    if (sdx*sdx + sdy*sdy < minPx2) continue

                    ctx.moveTo(px(ax), py(ay))
                    ctx.lineTo(px(bx), py(by))
                }
                ctx.stroke()
                ctx.globalAlpha = 1.0
            }

            var showGlow = sc >= graphView.glowVisibleScale
            for (var i = 0; i < nodes.length; i++) {
                var nx = pos[i].x, ny = pos[i].y
                if (!inView(nx, ny)) continue

                var s   = nodes[i].state
                var col = s === 1 ? graphView.colInfected
                        : s === 2 ? graphView.colRecovered
                        : graphView.colHealthy
                var spx = px(nx), spy = py(ny)

                if (s === 1 && showGlow) {
                    ctx.beginPath()
                    ctx.arc(spx, spy, nr * 2.5, 0, 2 * Math.PI)
                    ctx.fillStyle = Qt.rgba(0.94, 0.27, 0.27, 0.12)
                    ctx.fill()
                }

                ctx.beginPath()
                ctx.arc(spx, spy, nr, 0, 2 * Math.PI)
                ctx.fillStyle = col
                ctx.fill()
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        property real lastX: 0; property real lastY: 0
        onPressed:  function(m) { lastX = m.x; lastY = m.y }
        onPositionChanged: function(m) {
            graphView.viewOffX += m.x - lastX
            graphView.viewOffY += m.y - lastY
            lastX = m.x; lastY = m.y
            canvas.requestPaint()
        }
        onWheel: function(w) {
            var f  = w.angleDelta.y > 0 ? 1.15 : 0.87
            var ns = Math.max(0.1, Math.min(12.0, graphView.viewScale * f))
            graphView.viewOffX = w.x - (w.x - graphView.viewOffX) * (ns / graphView.viewScale)
            graphView.viewOffY = w.y - (w.y - graphView.viewOffY) * (ns / graphView.viewScale)
            graphView.viewScale = ns
            canvas.requestPaint()
        }
        cursorShape: Qt.OpenHandCursor
    }

    Rectangle {
        anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 16
        width: zoomRow.implicitWidth + 24; height: 48
        color: Qt.rgba(0.07, 0.09, 0.13, 0.88); radius: 8
        border.color: graphView.colBorder; border.width: 1

        Row {
            id: zoomRow
            anchors.centerIn: parent; spacing: 6
            Repeater {
                model: [
                    { lbl: "+", act: function() { graphView.viewScale = Math.min(12, graphView.viewScale * 1.25); canvas.requestPaint() } },
                    { lbl: "−", act: function() { graphView.viewScale = Math.max(0.1, graphView.viewScale * 0.8);  canvas.requestPaint() } },
                    { lbl: "⌂", act: function() { graphView.viewScale = 1; graphView.viewOffX = 0; graphView.viewOffY = 0; canvas.requestPaint() } }
                ]
                Rectangle {
                    width: 32; height: 32; radius: 4
                    color: zoomMa.containsMouse ? "#2a3a55" : "transparent"
                    border.color: graphView.colBorder; border.width: 1
                    Text { anchors.centerIn: parent; text: modelData.lbl; color: graphView.colTxt; font.pixelSize: 16; font.bold: true }
                    MouseArea { id: zoomMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.act() }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 16
        width: 130; height: 86
        color: Qt.rgba(0.07, 0.09, 0.13, 0.88); radius: 8
        border.color: graphView.colBorder; border.width: 1
        Column {
            anchors.centerIn: parent; spacing: 10
            Repeater {
                model: [
                    { col: graphView.colHealthy,   lbl: "Healthy"   },
                    { col: graphView.colInfected,  lbl: "Infected"  },
                    { col: graphView.colRecovered, lbl: "Recovered" }
                ]
                Row {
                    spacing: 8
                    Rectangle { width: 10; height: 10; radius: 5; color: modelData.col; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: modelData.lbl; color: graphView.colTxt; font.pixelSize: 12 }
                }
            }
        }
    }

    Text {
        id: statusText
        anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter; anchors.topMargin: 12
        text: "Load a graph to visualize"; color: graphView.colMuted; font.pixelSize: 11
    }

    Column {
        anchors.centerIn: parent; spacing: 14; visible: !graphView.simLoaded
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "🕸️"; font.pixelSize: 52 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Graph will appear here after loading"; color: graphView.colMuted; font.pixelSize: 14 }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Pan: drag  ·  Zoom: scroll or buttons"; color: "#3a4a65"; font.pixelSize: 11 }
    }
}
