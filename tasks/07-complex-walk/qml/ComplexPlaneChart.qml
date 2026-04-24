import QtQuick
import "."

Item {
    id: chart

    property var    path:          []
    property bool   returned:      false
    property int    return_step:   -1
    property double rho:           1.0
    property int    n_dirs:        4

    onPathChanged:     canvas.requestPaint()
    onReturnedChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var padL = 48, padR = 24, padT = 24, padB = 48
            var W = width  - padL - padR
            var H = height - padT - padB
            if (W <= 0 || H <= 0) return

            var pts = chart.path
            if (pts.length < 2) {
                ctx.fillStyle = "#3a2f60"; ctx.font = "13px monospace"; ctx.textAlign = "center"
                ctx.fillText("Run a simulation to see trajectory", padL + W / 2, padT + H / 2)
                return
            }

            var minX = pts[0].x, maxX = pts[0].x
            var minY = pts[0].y, maxY = pts[0].y
            for (var i = 1; i < pts.length; i++) {
                if (pts[i].x < minX) minX = pts[i].x
                if (pts[i].x > maxX) maxX = pts[i].x
                if (pts[i].y < minY) minY = pts[i].y
                if (pts[i].y > maxY) maxY = pts[i].y
            }

            var span = Math.max(maxX - minX, maxY - minY, chart.rho * 2)
            var cx0  = (minX + maxX) / 2
            var cy0  = (minY + maxY) / 2
            var pad  = span * 0.15
            minX = cx0 - span / 2 - pad; maxX = cx0 + span / 2 + pad
            minY = cy0 - span / 2 - pad; maxY = cy0 + span / 2 + pad
            var xRange = maxX - minX
            var yRange = maxY - minY

            function toSX(x) { return padL + (x - minX) / xRange * W }
            function toSY(y) { return padT + (1.0 - (y - minY) / yRange) * H }

            // Grid
            ctx.strokeStyle = "#2a2048"; ctx.lineWidth = 1
            var gridSteps = 5
            for (var gi = 0; gi <= gridSteps; gi++) {
                var gx = padL + gi / gridSteps * W
                var gy = padT + gi / gridSteps * H
                ctx.beginPath(); ctx.moveTo(gx, padT); ctx.lineTo(gx, padT + H); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(padL + W, gy); ctx.stroke()
                var gxv = minX + gi / gridSteps * xRange
                var gyv = maxY - gi / gridSteps * yRange
                ctx.fillStyle = "#a5a1b8"; ctx.font = "9px monospace"
                ctx.textAlign = "center"; ctx.fillText(gxv.toFixed(1), gx, padT + H + 14)
                ctx.textAlign = "right";  ctx.fillText(gyv.toFixed(1), padL - 4, gy + 3)
            }

            // Axes
            var ox = toSX(0), oy = toSY(0)
            if (ox >= padL && ox <= padL + W) {
                ctx.beginPath(); ctx.strokeStyle = "rgba(160,145,184,0.3)"; ctx.lineWidth = 1
                ctx.moveTo(ox, padT); ctx.lineTo(ox, padT + H); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"; ctx.textAlign = "left"
                ctx.fillText("Im", ox + 4, padT + 10)
            }
            if (oy >= padT && oy <= padT + H) {
                ctx.beginPath(); ctx.strokeStyle = "rgba(160,145,184,0.3)"; ctx.lineWidth = 1
                ctx.moveTo(padL, oy); ctx.lineTo(padL + W, oy); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"; ctx.textAlign = "left"
                ctx.fillText("Re", padL + W - 18, oy - 4)
            }

            // Direction indicators at origin (faint)
            var twoPi = 2 * Math.PI
            ctx.strokeStyle = "rgba(139,92,246,0.15)"; ctx.lineWidth = 1
            for (var di = 0; di < chart.n_dirs; di++) {
                var angle = twoPi / chart.n_dirs * di
                var ex = toSX(chart.rho * Math.cos(angle))
                var ey = toSY(chart.rho * Math.sin(angle))
                ctx.beginPath(); ctx.moveTo(ox, oy); ctx.lineTo(ex, ey); ctx.stroke()
            }

            // Fill area enclosed
            ctx.beginPath()
            ctx.moveTo(toSX(pts[0].x), toSY(pts[0].y))
            for (var fi = 1; fi < pts.length; fi++)
                ctx.lineTo(toSX(pts[fi].x), toSY(pts[fi].y))
            ctx.closePath()
            ctx.fillStyle = chart.returned
                ? "rgba(52,211,153,0.05)"
                : "rgba(139,92,246,0.05)"
            ctx.fill()

            // Trajectory
            ctx.beginPath()
            ctx.strokeStyle = chart.returned ? "#34d399" : "#8b5cf6"
            ctx.lineWidth   = 1.5
            ctx.lineJoin    = "round"
            ctx.moveTo(toSX(pts[0].x), toSY(pts[0].y))
            for (var li = 1; li < pts.length; li++)
                ctx.lineTo(toSX(pts[li].x), toSY(pts[li].y))
            ctx.stroke()

            // Step dots
            var dotEvery = Math.max(1, Math.floor(pts.length / 80))
            for (var si = 0; si < pts.length; si += dotEvery) {
                ctx.beginPath()
                ctx.arc(toSX(pts[si].x), toSY(pts[si].y), 2, 0, Math.PI * 2)
                ctx.fillStyle = chart.returned ? "#34d399" : "#8b5cf6"
                ctx.fill()
            }

            // Origin marker
            ctx.beginPath(); ctx.arc(ox, oy, 5, 0, Math.PI * 2)
            ctx.fillStyle = "#fbbf24"; ctx.fill()
            ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1.5; ctx.stroke()

            // Start = origin, end dot
            var ep = pts[pts.length - 1]
            ctx.beginPath(); ctx.arc(toSX(ep.x), toSY(ep.y), 5, 0, Math.PI * 2)
            ctx.fillStyle = chart.returned ? "#34d399" : "#f87171"
            ctx.fill(); ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1.5; ctx.stroke()

            // Info label
            ctx.fillStyle = chart.returned ? "#34d399" : "#f87171"
            ctx.font = "bold 12px monospace"; ctx.textAlign = "right"
            ctx.fillText(
                chart.returned
                    ? "↩ returned at step " + chart.return_step
                    : "steps: " + (pts.length - 1) + "  (no return)",
                padL + W, padT - 6
            )

            // Axis labels
            ctx.fillStyle = "#a5a1b8"; ctx.font = "11px monospace"; ctx.textAlign = "center"
            ctx.fillText("Re", padL + W / 2, height - 2)
            ctx.save(); ctx.translate(11, padT + H / 2); ctx.rotate(-Math.PI / 2)
            ctx.fillText("Im", 0, 0); ctx.restore()
        }
    }
}
