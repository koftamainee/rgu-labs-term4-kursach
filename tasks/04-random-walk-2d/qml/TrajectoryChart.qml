import QtQuick
import "."

Item {
    id: chart

    property var    trajectory: []
    property int    l_crossings: 0
    property double h_step: 1.0

    onTrajectoryChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var padL = 48, padR = 20, padT = 20, padB = 36
            var W = width  - padL - padR
            var H = height - padT - padB
            if (W <= 0 || H <= 0) return

            var pts = chart.trajectory
            if (pts.length < 2) {
                ctx.fillStyle = "#3a2f60"; ctx.font = "13px monospace"; ctx.textAlign = "center"
                ctx.fillText("Run a simulation to see trajectory", padL + W / 2, padT + H / 2)
                return
            }

            var minY = pts[0].y, maxY = pts[0].y
            for (var i = 1; i < pts.length; i++) {
                if (pts[i].y < minY) minY = pts[i].y
                if (pts[i].y > maxY) maxY = pts[i].y
            }
            var yRange = maxY - minY
            if (yRange < 1e-9) { minY -= 1; maxY += 1; yRange = 2 }
            minY -= yRange * 0.1
            maxY += yRange * 0.1
            yRange = maxY - minY

            var xMin = pts[0].x, xMax = pts[pts.length - 1].x
            var xRange = xMax - xMin
            if (xRange < 1e-9) xRange = 1

            function toX(x) { return padL + (x - xMin) / xRange * W }
            function toY(y) { return padT + (1.0 - (y - minY) / yRange) * H }

            // Grid
            ctx.strokeStyle = "#2a2048"
            ctx.lineWidth   = 1
            var ySteps = 6
            for (var gi = 0; gi <= ySteps; gi++) {
                var gv = minY + gi / ySteps * yRange
                var gy = toY(gv)
                ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(padL + W, gy); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"; ctx.textAlign = "right"
                ctx.fillText(gv.toFixed(1), padL - 5, gy + 3)
            }
            var xSteps = Math.min(pts.length - 1, 10)
            for (var xi = 0; xi <= xSteps; xi++) {
                var xv = xMin + xi / xSteps * xRange
                var gx = toX(xv)
                ctx.beginPath(); ctx.strokeStyle = "#2a2048"; ctx.moveTo(gx, padT); ctx.lineTo(gx, padT + H); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"; ctx.textAlign = "center"
                ctx.fillText(xv.toFixed(1), gx, padT + H + 16)
            }

            // Zero line
            if (minY <= 0 && maxY >= 0) {
                var zy = toY(0)
                ctx.beginPath()
                ctx.strokeStyle = "rgba(248,113,113,0.5)"
                ctx.lineWidth   = 1.5
                ctx.setLineDash([6, 4])
                ctx.moveTo(padL, zy); ctx.lineTo(padL + W, zy); ctx.stroke()
                ctx.setLineDash([])
                ctx.fillStyle = "#f87171"; ctx.font = "10px monospace"; ctx.textAlign = "right"
                ctx.fillText("y=0", padL - 5, zy + 3)
            }

            // Axis labels
            ctx.fillStyle = "#a5a1b8"; ctx.font = "11px monospace"
            ctx.textAlign = "center"
            ctx.fillText("x", padL + W / 2, height - 2)
            ctx.save(); ctx.translate(11, padT + H / 2); ctx.rotate(-Math.PI / 2)
            ctx.fillText("y", 0, 0); ctx.restore()

            // Fill area under curve
            ctx.beginPath()
            ctx.moveTo(toX(pts[0].x), toY(0))
            for (var fi = 0; fi < pts.length; fi++)
                ctx.lineTo(toX(pts[fi].x), toY(pts[fi].y))
            ctx.lineTo(toX(pts[pts.length - 1].x), toY(0))
            ctx.closePath()
            ctx.fillStyle = "rgba(139,92,246,0.07)"
            ctx.fill()

            // Trajectory line
            ctx.beginPath()
            ctx.strokeStyle = "#8b5cf6"
            ctx.lineWidth   = 2
            ctx.lineJoin    = "round"
            ctx.moveTo(toX(pts[0].x), toY(pts[0].y))
            for (var li = 1; li < pts.length; li++)
                ctx.lineTo(toX(pts[li].x), toY(pts[li].y))
            ctx.stroke()

            // Dots at each step
            for (var di = 0; di < pts.length; di++) {
                ctx.beginPath()
                ctx.arc(toX(pts[di].x), toY(pts[di].y), 3, 0, Math.PI * 2)
                ctx.fillStyle = "#8b5cf6"; ctx.fill()
                ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1; ctx.stroke()
            }

            // Start dot
            ctx.beginPath()
            ctx.arc(toX(pts[0].x), toY(pts[0].y), 5, 0, Math.PI * 2)
            ctx.fillStyle = "#34d399"; ctx.fill()
            ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1.5; ctx.stroke()

            // Crossings label top right
            ctx.fillStyle = "#fbbf24"; ctx.font = "bold 12px monospace"; ctx.textAlign = "right"
            ctx.fillText("crossings: " + chart.l_crossings, padL + W, padT - 4)
        }
    }
}
