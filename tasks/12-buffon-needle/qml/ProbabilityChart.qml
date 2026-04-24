import QtQuick
import "."

Item {
    id: chart

    property var    dataPoints: []
    property double currentL:   needle_controller.l
    property double currentD:   needle_controller.d
    property double simProb:    needle_controller.sim_prob
    property double exactProb:  needle_controller.exact_prob

    onDataPointsChanged: canvas.requestPaint()
    onCurrentLChanged:   canvas.requestPaint()
    onSimProbChanged:    canvas.requestPaint()
    onExactProbChanged:  canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var padL = 44, padR = 24, padT = 24, padB = 44
            var W = width  - padL - padR
            var H = height - padT - padB
            if (W <= 0 || H <= 0) return

            ctx.strokeStyle = "#2a2048"
            ctx.lineWidth = 1

            for (var i = 0; i <= 5; i++) {
                var val = i / 5.0
                var yg = padT + H - val * H
                ctx.beginPath(); ctx.moveTo(padL, yg); ctx.lineTo(padL + W, yg); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"
                ctx.textAlign = "right"
                ctx.fillText(val.toFixed(1), padL - 6, yg + 4)
            }

            for (var li = 0; li <= 10; li++) {
                var xg = padL + (li / 10.0) * W
                ctx.beginPath(); ctx.moveTo(xg, padT); ctx.lineTo(xg, padT + H); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "10px monospace"
                ctx.textAlign = "center"
                ctx.fillText((li / 10.0).toFixed(1), xg, padT + H + 16)
            }

            ctx.fillStyle = "#a5a1b8"; ctx.font = "11px monospace"
            ctx.textAlign = "center"
            ctx.fillText("L / d  (needle-to-spacing ratio)", padL + W / 2, height - 4)
            ctx.save()
            ctx.translate(11, padT + H / 2)
            ctx.rotate(-Math.PI / 2)
            ctx.fillText("crossing probability", 0, 0)
            ctx.restore()

            ctx.fillStyle = "#fbbf24"; ctx.font = "bold 12px monospace"
            ctx.textAlign = "right"
            ctx.fillText("d=" + chart.currentD.toFixed(2) + "  L=" + chart.currentL.toFixed(2),
                         padL + W, padT - 6)

            ctx.beginPath()
            ctx.strokeStyle = "rgba(251,191,36,0.7)"
            ctx.lineWidth = 2
            ctx.setLineDash([])
            var first = true
            for (var t = 0; t <= 100; t++) {
                var ratio = t / 100.0
                var prob  = (2.0 * ratio) / Math.PI
                var xt = padL + ratio * W
                var yt = padT + H - prob * H
                if (first) { ctx.moveTo(xt, yt); first = false }
                else ctx.lineTo(xt, yt)
            }
            ctx.stroke()

            var pts = chart.dataPoints
            if (pts.length >= 2) {
                ctx.beginPath()
                ctx.strokeStyle = "#f87171"; ctx.lineWidth = 2; ctx.lineJoin = "round"
                ctx.setLineDash([])
                for (var k = 0; k < pts.length; k++) {
                    var dp  = pts[k]
                    var px  = padL + dp.ratio * W
                    var py  = padT + H - dp.sim_prob * H
                    if (k === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py)
                }
                ctx.stroke()
            }

            var curRatio = chart.currentL / chart.currentD
            if (curRatio >= 0 && curRatio <= 1) {
                var cx = padL + curRatio * W
                ctx.beginPath(); ctx.strokeStyle = "#8b5cf6"; ctx.lineWidth = 1.5
                ctx.setLineDash([5, 4])
                ctx.moveTo(cx, padT); ctx.lineTo(cx, padT + H); ctx.stroke()
                ctx.setLineDash([])

                if (chart.exactProb >= 0) {
                    var ey = padT + H - chart.exactProb * H
                    ctx.beginPath(); ctx.arc(cx, ey, 5, 0, Math.PI * 2)
                    ctx.fillStyle = "#fbbf24"; ctx.fill()
                    ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1.5; ctx.stroke()
                    ctx.fillStyle = "#fbbf24"; ctx.font = "bold 10px monospace"; ctx.textAlign = "left"
                    ctx.fillText(chart.exactProb.toFixed(4), cx + 8, ey + 4)
                }

                if (chart.simProb > 0) {
                    var sy = padT + H - chart.simProb * H
                    ctx.beginPath(); ctx.arc(cx, sy, 5, 0, Math.PI * 2)
                    ctx.fillStyle = "#f87171"; ctx.fill()
                    ctx.strokeStyle = "#0f0c1f"; ctx.lineWidth = 1.5; ctx.stroke()
                    ctx.fillStyle = "#f87171"; ctx.font = "bold 10px monospace"; ctx.textAlign = "left"
                    ctx.fillText(chart.simProb.toFixed(4), cx + 8, sy - 6)
                }
            }

            var lx = padL + 10, ly = padT + 10
            ctx.strokeStyle = "#fbbf24"; ctx.lineWidth = 2
            ctx.setLineDash([])
            ctx.beginPath(); ctx.moveTo(lx, ly + 2); ctx.lineTo(lx + 18, ly + 2); ctx.stroke()
            ctx.fillStyle = Theme.txt; ctx.font = "11px monospace"; ctx.textAlign = "left"
            ctx.fillText("P = 2L/(\u03c0d)  exact", lx + 22, ly + 6)

            ctx.strokeStyle = "#f87171"; ctx.lineWidth = 2
            ctx.beginPath(); ctx.moveTo(lx, ly + 18); ctx.lineTo(lx + 18, ly + 18); ctx.stroke()
            ctx.fillStyle = Theme.txt
            ctx.fillText("P  simulation", lx + 22, ly + 22)
        }
    }
}
