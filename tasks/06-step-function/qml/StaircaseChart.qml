import QtQuick
import "."

Item {
    id: chart

    property var    steps:             []
    property bool   strictly_increasing: false
    property int    generation_index:  0
    property double tau:               1.0
    property double h:                 1.0
    property int    seg_m:             10

    onStepsChanged:              canvas.requestPaint()
    onStrictly_increasingChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var padL = 36, padR = 16, padT = 20, padB = 28
            var W = width  - padL - padR
            var H = height - padT - padB
            if (W <= 0 || H <= 0 || chart.steps.length === 0) return

            var pts = chart.steps
            var n   = pts.length
            var segW = W / n

            var maxVal = 0
            for (var i = 0; i < n; i++)
                if (pts[i] > maxVal) maxVal = pts[i]
            if (maxVal <= 0) maxVal = chart.tau

            ctx.strokeStyle = "#2a2048"
            ctx.lineWidth   = 1
            for (var gi = 0; gi <= 4; gi++) {
                var gv = gi / 4.0 * maxVal
                var gy = padT + H - (gv / maxVal) * H
                ctx.beginPath(); ctx.moveTo(padL, gy); ctx.lineTo(padL + W, gy); ctx.stroke()
                ctx.fillStyle = "#a5a1b8"; ctx.font = "9px monospace"; ctx.textAlign = "right"
                ctx.fillText(gv.toFixed(1), padL - 4, gy + 3)
            }

            for (var si = 0; si <= n; si++) {
                var sx = padL + si * segW
                ctx.beginPath()
                ctx.strokeStyle = "#2a2048"
                ctx.moveTo(sx, padT); ctx.lineTo(sx, padT + H); ctx.stroke()
                if (si < n) {
                    ctx.fillStyle = "#3a2f60"; ctx.font = "8px monospace"; ctx.textAlign = "center"
                    ctx.fillText((si * chart.h).toFixed(0), padL + (si + 0.5) * segW, padT + H + 14)
                }
            }

            var isInc = chart.strictly_increasing
            var fillBase = isInc
                ? "rgba(52,211,153,0.09)"
                : "rgba(248,113,113,0.07)"
            var strokeC = isInc ? "#34d399" : "#f87171"

            for (var k = 0; k < n; k++) {
                var x0 = padL + k * segW
                var x1 = padL + (k + 1) * segW
                var yv = padT + H - (pts[k] / maxVal) * H
                ctx.fillStyle = fillBase
                ctx.fillRect(x0, yv, segW, padT + H - yv)
            }

            ctx.beginPath()
            ctx.strokeStyle = strokeC
            ctx.lineWidth   = 2
            ctx.lineJoin    = "round"
            for (var j = 0; j < n; j++) {
                var jx0 = padL + j * segW
                var jx1 = padL + (j + 1) * segW
                var jy  = padT + H - (pts[j] / maxVal) * H
                if (j === 0) ctx.moveTo(jx0, jy)
                else {
                    var prevy = padT + H - (pts[j - 1] / maxVal) * H
                    ctx.lineTo(jx0, prevy)
                    ctx.lineTo(jx0, jy)
                }
                ctx.lineTo(jx1, jy)
            }
            ctx.stroke()

            ctx.fillStyle = isInc ? "#34d399" : "#f87171"
            ctx.font      = "bold 9px monospace"
            ctx.textAlign = "right"
            ctx.fillText("#" + (chart.generation_index + 1), padL + W, padT - 4)
        }
    }

    Rectangle {
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.margins: 4
        width: 7; height: 7; radius: 3.5
        color: chart.strictly_increasing ? Theme.success : Theme.danger
    }
}
