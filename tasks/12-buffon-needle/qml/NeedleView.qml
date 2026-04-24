import QtQuick
import "."

Item {
    id: nv

    property double d:       needle_controller.d
    property double l:       needle_controller.l
    property var    needles: []

    onNeedlesChanged: canvas.requestPaint()
    onDChanged:       canvas.requestPaint()
    onLChanged:       canvas.requestPaint()

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#0a0718" }
            GradientStop { position: 1.0; color: "#0f0c1f" }
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            var padL = 24, padR = 24, padT = 24, padB = 24
            var W = width  - padL - padR
            var H = height - padT - padB
            if (W <= 0 || H <= 0) return

            var d   = nv.d
            var L   = nv.l
            var lineCount = Math.floor(H / (H / Math.max(4, Math.round(H / 60)))) + 2
            var spacing   = H / lineCount

            ctx.strokeStyle = Theme.border
            ctx.lineWidth = 1
            ctx.setLineDash([])
            for (var i = 0; i <= lineCount; i++) {
                var yLine = padT + i * spacing
                ctx.beginPath()
                ctx.moveTo(padL, yLine)
                ctx.lineTo(padL + W, yLine)
                ctx.stroke()

                ctx.fillStyle = Theme.muted
                ctx.font = "9px monospace"
                ctx.textAlign = "right"
                ctx.fillText(i.toString(), padL - 6, yLine + 4)
            }

            var pts = nv.needles
            for (var j = 0; j < pts.length; j++) {
                var needle = pts[j]

                var nx   = needle.x
                var phi  = needle.phi

                var randStrip = Math.floor(Math.random() * lineCount)
                var baseY = padT + randStrip * spacing + nx / (d / 2) * spacing / 2

                var halfProj = (L / 2.0) * Math.sin(phi)
                var cosComp  = (L / 2.0) * Math.cos(phi)

                var cx = padL + (j / Math.max(pts.length - 1, 1)) * W
                var cy = baseY

                var x1 = cx - cosComp / d * spacing * 4
                var y1 = cy - halfProj / (d / 2) * spacing / 2
                var x2 = cx + cosComp / d * spacing * 4
                var y2 = cy + halfProj / (d / 2) * spacing / 2

                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.strokeStyle = needle.crosses
                    ? Qt.rgba(Theme.danger.r, Theme.danger.g, Theme.danger.b, 0.85)
                    : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                ctx.lineWidth = 1.5
                ctx.stroke()

                if (needle.crosses) {
                    ctx.beginPath()
                    ctx.arc(cx, cy, 2, 0, Math.PI * 2)
                    ctx.fillStyle = Theme.danger
                    ctx.fill()
                }
            }

            if (pts.length === 0) {
                ctx.fillStyle = Theme.muted
                ctx.font = "14px monospace"
                ctx.textAlign = "center"
                ctx.fillText("Press \u00abVisualize\u00bb to throw needles", padL + W / 2, padT + H / 2)
            }

            ctx.fillStyle = "#f87171"
            ctx.fillRect(padL + 10, padT + 10, 18, 3)
            ctx.fillStyle = Theme.txt
            ctx.font = "11px monospace"
            ctx.textAlign = "left"
            ctx.fillText("Crosses a line", padL + 32, padT + 14)

            ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85)
            ctx.fillRect(padL + 10, padT + 26, 18, 3)
            ctx.fillStyle = Theme.txt
            ctx.fillText("Does not cross", padL + 32, padT + 30)
        }
    }
}
