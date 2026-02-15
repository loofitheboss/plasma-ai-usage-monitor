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
    required property var backend // QtObject or ProviderBackend with usage properties
    property bool showCost: false   // Only OpenAI has cost data
    property bool showUsage: false  // Only OpenAI has historical usage data

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

        ColumnLayout {
            id: cardContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.mediumSpacing

            // Header row: provider name + status
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Provider color indicator
                Rectangle {
                    width: 4
                    Layout.preferredHeight: providerLabel.implicitHeight
                    radius: 2
                    color: card.providerColor
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
                }

                // Loading spinner
                PlasmaComponents.BusyIndicator {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    visible: card.backend?.loading ?? false
                    running: visible
                }
            }

            // Error message
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: (card.backend?.error ?? "") !== ""
                text: card.backend?.error ?? ""
                color: Kirigami.Theme.negativeTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                wrapMode: Text.WordWrap
            }

            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: card.backend?.connected ?? false
            }

            // Usage data (only for providers with usage APIs, i.e., OpenAI)
            GridLayout {
                Layout.fillWidth: true
                visible: card.showUsage && (card.backend?.connected ?? false)
                columns: 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                // Input tokens
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

                // Output tokens
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

                // Total tokens
                PlasmaComponents.Label {
                    text: i18n("Total tokens:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
                PlasmaComponents.Label {
                    text: formatNumber(card.backend?.totalTokens ?? 0)
                    font.bold: true
                    Layout.alignment: Qt.AlignRight
                }

                // Request count
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

            // Cost display (OpenAI only)
            RowLayout {
                Layout.fillWidth: true
                visible: card.showCost && (card.backend?.connected ?? false)
                spacing: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: i18n("Cost:")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
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

            // Separator before rate limits
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: card.backend?.connected ?? false
            }

            // Rate limits section
            ColumnLayout {
                Layout.fillWidth: true
                visible: card.backend?.connected ?? false
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

            // Last refreshed
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: card.backend?.connected ?? false
                horizontalAlignment: Text.AlignRight
                text: i18n("Updated: %1", Qt.formatTime(card.backend?.lastRefreshed ?? new Date(), "hh:mm:ss"))
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.4
            }
        }
    }

    // Color helper: green->yellow->red based on remaining/total ratio
    function rateLimitColor(remaining, total) {
        if (total <= 0) return Kirigami.Theme.disabledTextColor;
        var ratio = remaining / total; // 1.0 = full, 0.0 = depleted
        if (ratio > 0.5) return Kirigami.Theme.positiveTextColor;
        if (ratio > 0.2) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.negativeTextColor;
    }

    // Format large numbers with K/M suffixes
    function formatNumber(n) {
        if (n >= 1000000) return (n / 1000000).toFixed(1) + "M";
        if (n >= 1000) return (n / 1000).toFixed(1) + "K";
        return n.toString();
    }
}
