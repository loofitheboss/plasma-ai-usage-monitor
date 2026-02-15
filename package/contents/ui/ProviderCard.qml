import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: card

    required property string providerName
    required property string providerIcon
    required property string providerColor
    required property var backend
    property bool showCost: false
    property bool showUsage: false
    property bool collapsed: false

    spacing: 0

    // Card background
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: cardContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: {
            var base = Kirigami.Theme.backgroundColor;
            return Qt.darker(base, 1.05);
        }
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.1)

        Accessible.role: Accessible.Grouping
        Accessible.name: {
            var status = "";
            if (!card.backend) status = i18n("not available");
            else if (card.backend.error) status = i18n("error");
            else if (card.backend.connected) status = i18n("connected");
            else status = i18n("disconnected");

            var desc = card.providerName + ", " + status;
            if (card.backend && card.backend.connected && card.showCost) {
                desc += ", $" + (card.backend.cost ?? 0).toFixed(4);
            }
            return desc;
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        clip: true

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.mediumSpacing

            // Header row: provider name + status (clickable to collapse/expand)
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Provider color indicator
                Rectangle {
                    width: 4
                    Layout.preferredHeight: providerLabel.implicitHeight
                    radius: 2
                    color: card.providerColor

                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }

                Kirigami.Icon {
                    source: card.providerIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                PlasmaExtras.Heading {
                    id: providerLabel
                    level: 4
                    text: card.providerName
                    Layout.fillWidth: true
                }

                // Error count badge
                Rectangle {
                    visible: (card.backend?.errorCount ?? 0) > 0
                    width: errorCountLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                    height: errorCountLabel.implicitHeight + Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: Kirigami.Theme.negativeBackgroundColor

                    PlasmaComponents.Label {
                        id: errorCountLabel
                        anchors.centerIn: parent
                        text: (card.backend?.errorCount ?? 0).toString()
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: Kirigami.Theme.negativeTextColor
                    }
                }

                // Connection status
                PlasmaComponents.Label {
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: {
                        if (!card.backend) return i18n("N/A");
                        if (card.backend.loading) return i18n("Loading...");
                        if (card.backend.error) return i18n("Error");
                        if (card.backend.connected) return i18n("Connected");
                        return i18n("Disconnected");
                    }
                    color: {
                        if (!card.backend) return Kirigami.Theme.disabledTextColor;
                        if (card.backend.error) return Kirigami.Theme.negativeTextColor;
                        if (card.backend.connected) return Kirigami.Theme.positiveTextColor;
                        return Kirigami.Theme.disabledTextColor;
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }

                // Loading spinner
                PlasmaComponents.BusyIndicator {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    visible: card.backend?.loading ?? false
                    running: visible
                }

                // Compact cost when collapsed
                PlasmaComponents.Label {
                    visible: card.collapsed && card.showCost && (card.backend?.connected ?? false)
                    text: "$" + (card.backend?.cost ?? 0).toFixed(2)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                // Collapse/expand toggle
                PlasmaComponents.ToolButton {
                    icon.name: card.collapsed ? "arrow-down" : "arrow-up"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    onClicked: card.collapsed = !card.collapsed
                    PlasmaComponents.ToolTip { text: card.collapsed ? i18n("Expand") : i18n("Collapse") }
                }
            }

            // Error message (expandable)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.error ?? "") !== ""
                spacing: Kirigami.Units.smallSpacing / 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        text: card.backend?.error ?? ""
                        color: Kirigami.Theme.negativeTextColor
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        wrapMode: Text.WordWrap
                        elide: errorExpanded ? Text.ElideNone : Text.ElideRight
                        maximumLineCount: errorExpanded ? -1 : 1
                    }

                    // Retry button
                    PlasmaComponents.ToolButton {
                        icon.name: "view-refresh"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        PlasmaComponents.ToolTip { text: i18n("Retry") }
                        onClicked: {
                            if (card.backend) card.backend.refresh();
                        }
                    }

                    // Expand/collapse error details
                    PlasmaComponents.ToolButton {
                        icon.name: errorExpanded ? "arrow-up" : "arrow-down"
                        display: PlasmaComponents.AbstractButton.IconOnly
                        visible: (card.backend?.consecutiveErrors ?? 0) > 1
                        PlasmaComponents.ToolTip { text: errorExpanded ? i18n("Collapse") : i18n("Details") }
                        onClicked: errorExpanded = !errorExpanded
                    }
                }

                // Expanded error details
                PlasmaComponents.Label {
                    Layout.fillWidth: true
                    visible: errorExpanded && (card.backend?.consecutiveErrors ?? 0) > 1
                    text: i18n("%1 consecutive errors", card.backend?.consecutiveErrors ?? 0)
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }
            }

            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
            }

            // Usage data (for providers with usage APIs)
            GridLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && card.showUsage && (card.backend?.connected ?? false)
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Input tokens:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.inputTokens ?? 0)
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: i18n("Output tokens:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.outputTokens ?? 0)
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }

                PlasmaComponents.Label {
                    text: i18n("Requests:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.requestCount ?? 0)
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }
            }

            // Cost display
            RowLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && card.showCost && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: (card.backend?.isEstimatedCost ?? false) ? i18n("Est. Cost:") : i18n("Cost:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                // Estimated cost indicator
                PlasmaComponents.Label {
                    visible: card.backend?.isEstimatedCost ?? false
                    text: "~"
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.italic: true
                    opacity: 0.5
                    PlasmaComponents.ToolTip {
                        text: i18n("Estimated from token usage and model pricing. Not from billing API.")
                    }
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: "$" + (card.backend?.cost ?? 0).toFixed(4)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    color: {
                        var c = card.backend?.cost ?? 0;
                        if (c > 10) return Kirigami.Theme.negativeTextColor;
                        if (c > 5) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.textColor;
                    }
                }
            }

            // Budget progress bars
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                // Daily budget bar
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: (card.backend?.dailyBudget ?? 0) > 0
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Daily budget")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: "$" + (card.backend?.dailyCost ?? 0).toFixed(2) + " / $" + (card.backend?.dailyBudget ?? 0).toFixed(2)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0
                        to: card.backend?.dailyBudget ?? 1
                        value: Math.min(card.backend?.dailyCost ?? 0, card.backend?.dailyBudget ?? 1)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4
                            radius: 2
                            color: budgetColor(card.backend?.dailyCost ?? 0, card.backend?.dailyBudget ?? 1)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Monthly budget bar
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: (card.backend?.monthlyBudget ?? 0) > 0
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Monthly budget")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: "$" + (card.backend?.monthlyCost ?? 0).toFixed(2) + " / $" + (card.backend?.monthlyBudget ?? 0).toFixed(2)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
                        from: 0
                        to: card.backend?.monthlyBudget ?? 1
                        value: Math.min(card.backend?.monthlyCost ?? 0, card.backend?.monthlyBudget ?? 1)

                        background: Rectangle {
                            implicitHeight: 4
                            radius: 2
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 4
                            radius: 2
                            color: budgetColor(card.backend?.monthlyCost ?? 0, card.backend?.monthlyBudget ?? 1)

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }

                    // Estimated monthly cost
                    PlasmaComponents.Label {
                        visible: (card.backend?.estimatedMonthlyCost ?? 0) > 0
                        text: i18n("Est. monthly: $%1", (card.backend?.estimatedMonthlyCost ?? 0).toFixed(2))
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.italic: true
                        opacity: 0.5
                    }
                }
            }

            // Separator before rate limits
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
            }

            // Rate limits section
            ColumnLayout {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Rate Limits")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                    opacity: 0.8
                }

                // Requests rate limit bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: (card.backend?.rateLimitRequests ?? 0) > 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Requests/min")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: (card.backend?.rateLimitRequestsRemaining ?? 0) + " / " + (card.backend?.rateLimitRequests ?? 0)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        from: 0
                        to: card.backend?.rateLimitRequests ?? 1
                        value: card.backend?.rateLimitRequestsRemaining ?? 0

                        background: Rectangle {
                            implicitHeight: 6
                            radius: 3
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 6
                            radius: 3
                            color: rateLimitColor(
                                card.backend?.rateLimitRequestsRemaining ?? 0,
                                card.backend?.rateLimitRequests ?? 1
                            )

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Tokens rate limit bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: (card.backend?.rateLimitTokens ?? 0) > 0

                    RowLayout {
                        Layout.fillWidth: true
                        PlasmaComponents.Label {
                            text: i18n("Tokens/min")
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        PlasmaComponents.Label {
                            text: formatNumber(card.backend?.rateLimitTokensRemaining ?? 0) + " / " + formatNumber(card.backend?.rateLimitTokens ?? 0)
                            font.pointSize: Kirigami.Theme.smallFont.pointSize
                        }
                    }

                    QQC2.ProgressBar {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        from: 0
                        to: card.backend?.rateLimitTokens ?? 1
                        value: card.backend?.rateLimitTokensRemaining ?? 0

                        background: Rectangle {
                            implicitHeight: 6
                            radius: 3
                            color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                        }

                        contentItem: Rectangle {
                            width: parent.visualPosition * parent.width
                            height: 6
                            radius: 3
                            color: rateLimitColor(
                                card.backend?.rateLimitTokensRemaining ?? 0,
                                card.backend?.rateLimitTokens ?? 1
                            )

                            Behavior on width {
                                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                            }
                            Behavior on color {
                                ColorAnimation { duration: 300 }
                            }
                        }
                    }
                }

                // Reset time
                PlasmaComponents.Label {
                    visible: (card.backend?.rateLimitResetTime ?? "") !== ""
                    text: i18n("Resets: %1", card.backend?.rateLimitResetTime ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                }
            }

            // Last refreshed with relative time
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !card.collapsed && (card.backend?.connected ?? false)
                horizontalAlignment: Text.AlignRight
                text: {
                    var lr = card.backend?.lastRefreshed;
                    if (!lr) return "";
                    return i18n("Updated: %1 (#%2)",
                        formatRelativeTime(lr),
                        card.backend?.refreshCount ?? 0);
                }
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.4
            }
        }
    }

    // ── State ──
    property bool errorExpanded: false

    // ── Helper functions ──

    function rateLimitColor(remaining, total) {
        if (total <= 0) return Kirigami.Theme.disabledTextColor;
        var ratio = remaining / total;
        if (ratio > 0.5) return Kirigami.Theme.positiveTextColor;
        if (ratio > 0.2) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.negativeTextColor;
    }

    function budgetColor(spent, budget) {
        if (budget <= 0) return Kirigami.Theme.disabledTextColor;
        var ratio = spent / budget;
        if (ratio < 0.5) return Kirigami.Theme.positiveTextColor;
        if (ratio < 0.8) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.negativeTextColor;
    }

    function formatNumber(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
        if (n >= 1000) return (n / 1000).toFixed(1) + "K";
        return n.toString();
    }

    function formatRelativeTime(dateTime) {
        var now = new Date();
        var diff = Math.floor((now - dateTime) / 1000);
        if (diff < 5) return i18n("just now");
        if (diff < 60) return i18n("%1s ago", diff);
        if (diff < 3600) return i18n("%1m ago", Math.floor(diff / 60));
        if (diff < 86400) return i18n("%1h ago", Math.floor(diff / 3600));
        return Qt.formatTime(dateTime, "hh:mm:ss");
    }
}
