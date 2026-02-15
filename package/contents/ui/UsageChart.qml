import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

/**
 * Canvas-based line/area chart for visualizing usage history data.
 *
 * Expects chartData to be a QVariantList of QVariantMap with keys:
 *   timestamp, inputTokens, outputTokens, requestCount, cost, dailyCost,
 *   rlRequests, rlRequestsRemaining, rlTokens, rlTokensRemaining
 */
Item {
    id: chartRoot

    property var chartData: []
    property string provider: ""
    property string metric: "cost"  // "cost", "tokens", "requests", "rateLimit"
    property color lineColor: Kirigami.Theme.highlightColor
    property color areaColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.15)
    property color gridColor: Qt.rgba(Kirigami.Theme.textColor.r,
                                       Kirigami.Theme.textColor.g,
                                       Kirigami.Theme.textColor.b, 0.1)

    implicitHeight: Kirigami.Units.gridUnit * 10

    // Metric selector row
    RowLayout {
        id: metricBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: [
                { label: i18n("Cost"), value: "cost" },
                { label: i18n("Tokens"), value: "tokens" },
                { label: i18n("Requests"), value: "requests" },
                { label: i18n("Rate Limit"), value: "rateLimit" }
            ]

            PlasmaComponents.ToolButton {
                text: modelData.label
                checked: chartRoot.metric === modelData.value
                onClicked: {
                    chartRoot.metric = modelData.value;
                    canvas.requestPaint();
                }
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                implicitHeight: Kirigami.Units.gridUnit * 1.5
            }
        }

        Item { Layout.fillWidth: true }
    }

    // Empty state
    PlasmaComponents.Label {
        anchors.centerIn: canvas
        visible: !chartData || chartData.length < 2
        text: i18n("Not enough data to display chart")
        opacity: 0.5
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    Canvas {
        id: canvas
        anchors.top: metricBar.bottom
        anchors.topMargin: Kirigami.Units.smallSpacing
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: chartData && chartData.length >= 2

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            var data = chartRoot.chartData;
            if (!data || data.length < 2) return;

            var w = canvas.width;
            var h = canvas.height;
            var marginLeft = 50;
            var marginRight = 10;
            var marginTop = 10;
            var marginBottom = 30;
            var chartW = w - marginLeft - marginRight;
            var chartH = h - marginTop - marginBottom;

            if (chartW <= 0 || chartH <= 0) return;

            // Extract values based on selected metric
            var values = extractValues(data);
            if (values.length === 0) return;

            // Compute min/max
            var minVal = values[0];
            var maxVal = values[0];
            for (var i = 1; i < values.length; i++) {
                if (values[i] < minVal) minVal = values[i];
                if (values[i] > maxVal) maxVal = values[i];
            }

            // Avoid flat line
            if (maxVal === minVal) {
                maxVal = minVal + 1;
            }

            // Add 10% padding to top
            var range = maxVal - minVal;
            maxVal += range * 0.1;

            // ── Draw grid ──
            ctx.strokeStyle = chartRoot.gridColor;
            ctx.lineWidth = 1;
            ctx.font = "10px sans-serif";
            ctx.fillStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                                     Kirigami.Theme.textColor.g,
                                     Kirigami.Theme.textColor.b, 0.5);
            ctx.textAlign = "right";

            var gridLines = 4;
            for (var g = 0; g <= gridLines; g++) {
                var gy = marginTop + chartH - (g / gridLines) * chartH;
                var gVal = minVal + (g / gridLines) * (maxVal - minVal);

                ctx.beginPath();
                ctx.moveTo(marginLeft, gy);
                ctx.lineTo(marginLeft + chartW, gy);
                ctx.stroke();

                ctx.fillText(formatValue(gVal), marginLeft - 5, gy + 4);
            }

            // ── Draw time labels on X axis ──
            ctx.textAlign = "center";
            var labelCount = Math.min(5, values.length);
            for (var lbl = 0; lbl < labelCount; lbl++) {
                var idx = Math.floor(lbl * (values.length - 1) / (labelCount - 1));
                var lx = marginLeft + (idx / (values.length - 1)) * chartW;
                var ts = data[idx].timestamp;
                ctx.fillText(formatTimestamp(ts), lx, h - 5);
            }

            // ── Draw area fill ──
            ctx.beginPath();
            ctx.moveTo(marginLeft, marginTop + chartH);
            for (var a = 0; a < values.length; a++) {
                var ax = marginLeft + (a / (values.length - 1)) * chartW;
                var ay = marginTop + chartH - ((values[a] - minVal) / (maxVal - minVal)) * chartH;
                ctx.lineTo(ax, ay);
            }
            ctx.lineTo(marginLeft + chartW, marginTop + chartH);
            ctx.closePath();
            ctx.fillStyle = chartRoot.areaColor;
            ctx.fill();

            // ── Draw line ──
            ctx.beginPath();
            ctx.strokeStyle = chartRoot.lineColor;
            ctx.lineWidth = 2;
            ctx.lineJoin = "round";
            ctx.lineCap = "round";

            for (var p = 0; p < values.length; p++) {
                var px = marginLeft + (p / (values.length - 1)) * chartW;
                var py = marginTop + chartH - ((values[p] - minVal) / (maxVal - minVal)) * chartH;
                if (p === 0) {
                    ctx.moveTo(px, py);
                } else {
                    ctx.lineTo(px, py);
                }
            }
            ctx.stroke();

            // ── Draw data points (if not too many) ──
            if (values.length <= 50) {
                ctx.fillStyle = chartRoot.lineColor;
                for (var d = 0; d < values.length; d++) {
                    var dx = marginLeft + (d / (values.length - 1)) * chartW;
                    var dy = marginTop + chartH - ((values[d] - minVal) / (maxVal - minVal)) * chartH;
                    ctx.beginPath();
                    ctx.arc(dx, dy, 3, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
        }

        // Repaint on resize
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    // Repaint when data changes
    onChartDataChanged: canvas.requestPaint()
    onMetricChanged: canvas.requestPaint()

    // ── Helper functions ──

    function extractValues(data) {
        var vals = [];
        for (var i = 0; i < data.length; i++) {
            var item = data[i];
            switch (chartRoot.metric) {
                case "cost":
                    vals.push(item.cost || 0);
                    break;
                case "tokens":
                    vals.push((item.inputTokens || 0) + (item.outputTokens || 0));
                    break;
                case "requests":
                    vals.push(item.requestCount || 0);
                    break;
                case "rateLimit":
                    // Show percentage of rate limit used
                    var total = item.rlRequests || 0;
                    var remaining = item.rlRequestsRemaining || 0;
                    if (total > 0) {
                        vals.push(((total - remaining) / total) * 100);
                    } else {
                        vals.push(0);
                    }
                    break;
                default:
                    vals.push(0);
            }
        }
        return vals;
    }

    function formatValue(val) {
        switch (chartRoot.metric) {
            case "cost":
                return "$" + val.toFixed(2);
            case "tokens":
                if (val >= 1000000) return (val / 1000000).toFixed(1) + "M";
                if (val >= 1000) return (val / 1000).toFixed(1) + "K";
                return Math.round(val).toString();
            case "requests":
                if (val >= 1000) return (val / 1000).toFixed(1) + "K";
                return Math.round(val).toString();
            case "rateLimit":
                return Math.round(val) + "%";
            default:
                return val.toFixed(1);
        }
    }

    function formatTimestamp(ts) {
        if (!ts) return "";
        var d;
        if (typeof ts === "string") {
            d = new Date(ts);
        } else {
            d = ts;
        }

        var now = new Date();
        var diffDays = Math.floor((now.getTime() - d.getTime()) / (24 * 60 * 60 * 1000));

        if (diffDays === 0) {
            // Today: show time
            return d.getHours().toString().padStart(2, '0') + ":" +
                   d.getMinutes().toString().padStart(2, '0');
        } else if (diffDays < 7) {
            // Within a week: show day name
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            return days[d.getDay()];
        } else {
            // Older: show date
            return (d.getMonth() + 1) + "/" + d.getDate();
        }
    }
}
