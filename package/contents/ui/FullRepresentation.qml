import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import com.github.loofi.aiusagemonitor 1.0

PlasmaExtras.Representation {
    id: fullRoot

    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 28

    header: PlasmaExtras.PlasmoidHeading {
        RowLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: "cpu"
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
            }

            PlasmaExtras.Heading {
                level: 3
                text: i18n("AI Usage Monitor")
                Layout.fillWidth: true
            }

            PlasmaComponents.ToolButton {
                icon.name: "view-refresh"
                onClicked: root.refreshAll()
                PlasmaComponents.ToolTip { text: i18n("Refresh all providers") }
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                onClicked: plasmoid.internalAction("configure").trigger()
                PlasmaComponents.ToolTip { text: i18n("Configure...") }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // No providers configured message
        PlasmaExtras.PlaceholderMessage {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !hasAnyProvider()
            iconName: "network-disconnect"
            text: i18n("No providers configured")
            explanation: i18n("Open settings to add your API keys")

            helpfulAction: QQC2.Action {
                icon.name: "configure"
                text: i18n("Configure Providers")
                onTriggered: plasmoid.internalAction("configure").trigger()
            }
        }

        // Provider status summary bar
        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.smallSpacing
            visible: hasAnyProvider()
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: root.allProviders ?? []

                Rectangle {
                    visible: modelData.enabled
                    width: Kirigami.Units.smallSpacing * 3
                    height: width
                    radius: width / 2
                    color: {
                        if (!modelData.backend) return Kirigami.Theme.disabledTextColor;
                        if (modelData.backend.error) return Kirigami.Theme.negativeTextColor;
                        if (modelData.backend.connected) return Kirigami.Theme.positiveTextColor;
                        if (modelData.backend.loading) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.disabledTextColor;
                    }

                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }

                    PlasmaComponents.ToolTip {
                        text: modelData.name + ": " + (modelData.backend?.connected ? i18n("Connected") : i18n("Disconnected"))
                    }
                }
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Label {
                text: i18n("%1 active", root.connectedCount ?? 0)
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.6
            }
        }

        // Tab bar for Live / History views
        QQC2.TabBar {
            id: tabBar
            Layout.fillWidth: true
            visible: hasAnyProvider()

            QQC2.TabButton {
                text: i18n("Live")
                width: implicitWidth
            }
            QQC2.TabButton {
                text: i18n("History")
                width: implicitWidth
            }
        }

        // Tab content
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: hasAnyProvider()
            currentIndex: tabBar.currentIndex

            // ── Live Tab ──
            PlasmaComponents.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                contentItem: Flickable {
                    contentHeight: liveColumn.implicitHeight
                    clip: true

                    ColumnLayout {
                        id: liveColumn
                        width: parent.width
                        spacing: Kirigami.Units.mediumSpacing

                        // Cost summary card (shows total cost across all providers)
                        CostSummaryCard {
                            Layout.fillWidth: true
                            Layout.margins: Kirigami.Units.smallSpacing
                            visible: hasCostData()
                            providers: root.allProviders ?? []
                        }

                        // Provider cards (data-driven)
                        Repeater {
                            model: root.allProviders ?? []

                            ProviderCard {
                                Layout.fillWidth: true
                                visible: modelData.enabled
                                providerName: modelData.name
                                providerIcon: "globe"
                                providerColor: modelData.color
                                backend: modelData.backend ?? null
                                showCost: true
                                showUsage: true
                            }
                        }

                        // ── Subscription Tools Section ──
                        PlasmaExtras.Heading {
                            level: 5
                            text: i18n("Subscription Tools")
                            Layout.fillWidth: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                            Layout.topMargin: Kirigami.Units.largeSpacing
                            visible: root.enabledToolCount > 0
                            opacity: 0.7
                        }

                        Repeater {
                            model: root.allSubscriptionTools ?? []

                            SubscriptionToolCard {
                                Layout.fillWidth: true
                                Layout.leftMargin: Kirigami.Units.smallSpacing
                                Layout.rightMargin: Kirigami.Units.smallSpacing
                                visible: modelData.enabled
                                toolName: modelData.name
                                toolIcon: modelData.monitor?.iconName ?? "utilities-terminal"
                                toolColor: modelData.monitor?.toolColor ?? Kirigami.Theme.textColor
                                monitor: modelData.monitor ?? null
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }

            // ── History Tab ──
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                // Time range selector
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    PlasmaComponents.Label {
                        text: i18n("Range:")
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }

                    QQC2.ComboBox {
                        id: historyProviderCombo
                        model: getEnabledProviderNames()
                        Layout.fillWidth: true
                    }

                    QQC2.ComboBox {
                        id: timeRangeCombo
                        model: [i18n("24 hours"), i18n("7 days"), i18n("30 days")]
                        currentIndex: 1
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: "view-refresh"
                        onClicked: refreshHistory()
                        PlasmaComponents.ToolTip { text: i18n("Refresh history") }
                    }
                }

                // Usage chart
                UsageChart {
                    id: historyChart
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 10
                    Layout.margins: Kirigami.Units.smallSpacing
                }

                // Trend summary
                TrendSummary {
                    id: trendSummary
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                }

                // Export buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.margins: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.smallSpacing

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.ToolButton {
                        icon.name: "document-export"
                        text: i18n("CSV")
                        onClicked: exportData("csv")
                        PlasmaComponents.ToolTip { text: i18n("Export as CSV") }
                    }

                    PlasmaComponents.ToolButton {
                        icon.name: "document-export"
                        text: i18n("JSON")
                        onClicked: exportData("json")
                        PlasmaComponents.ToolTip { text: i18n("Export as JSON") }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Footer with last refresh time
        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.bottomMargin: Kirigami.Units.smallSpacing
            visible: hasAnyProvider()
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            text: {
                var interval = plasmoid.configuration.refreshInterval;
                if (interval >= 60) {
                    return i18n("Auto-refresh every %1 min", Math.floor(interval / 60));
                }
                return i18n("Auto-refresh every %1 sec", interval);
            }
        }
    }

    // ── Functions ──

    function hasAnyProvider() {
        return plasmoid.configuration.openaiEnabled
            || plasmoid.configuration.anthropicEnabled
            || plasmoid.configuration.googleEnabled
            || plasmoid.configuration.mistralEnabled
            || plasmoid.configuration.deepseekEnabled
            || plasmoid.configuration.groqEnabled
            || plasmoid.configuration.xaiEnabled
            || plasmoid.configuration.claudeCodeEnabled
            || plasmoid.configuration.codexEnabled
            || plasmoid.configuration.copilotEnabled;
    }

    function hasCostData() {
        var providers = root.allProviders ?? [];
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.cost > 0)
                return true;
        }
        return false;
    }

    function getEnabledProviderNames() {
        var names = [];
        var providers = root.allProviders ?? [];
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled) names.push(providers[i].name);
        }
        return names.length > 0 ? names : [i18n("No providers")];
    }

    function getTimeRange() {
        var now = new Date();
        switch (timeRangeCombo.currentIndex) {
            case 0: return new Date(now.getTime() - 24 * 60 * 60 * 1000);     // 24h
            case 1: return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000); // 7d
            case 2: return new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000); // 30d
            default: return new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        }
    }

    function refreshHistory() {
        if (!root.usageDb) return;
        var provider = historyProviderCombo.currentText;
        if (!provider || provider === i18n("No providers")) return;

        var from = getTimeRange();
        var to = new Date();

        var snapshots = root.usageDb.getSnapshots(provider, from, to);
        var summary = root.usageDb.getSummary(provider, from, to);
        var dailyCosts = root.usageDb.getDailyCosts(provider, from, to);

        historyChart.chartData = snapshots;
        historyChart.provider = provider;
        trendSummary.summaryData = summary;
        trendSummary.dailyCosts = dailyCosts;
        trendSummary.provider = provider;
    }

    function exportData(format) {
        if (!root.usageDb) return;
        var provider = historyProviderCombo.currentText;
        if (!provider || provider === i18n("No providers")) return;

        var from = getTimeRange();
        var to = new Date();

        var data;
        if (format === "csv") {
            data = root.usageDb.exportCsv(provider, from, to);
        } else {
            data = root.usageDb.exportJson(provider, from, to);
        }

        // Copy to clipboard
        if (data) {
            clipboard.setText(data);
        }
    }

    // Clipboard helper (C++ implementation)
    ClipboardHelper {
        id: clipboard
    }
}
