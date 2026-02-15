import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import com.github.loofi.aiusagemonitor 1.0

KCM.SimpleKCM {
    id: historyPage

    property alias cfg_historyEnabled: historySwitch.checked
    property alias cfg_historyRetentionDays: retentionSlider.value

    // Database reference for size display
    UsageDatabase {
        id: historyDb
        enabled: plasmoid.configuration.historyEnabled
        retentionDays: plasmoid.configuration.historyRetentionDays
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        // Master toggle
        QQC2.Switch {
            id: historySwitch
            Kirigami.FormData.label: i18n("Enable history:")
            checked: plasmoid.configuration.historyEnabled
        }

        QQC2.Label {
            text: i18n("When enabled, usage data is periodically saved to a local SQLite database for trend analysis and charts.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.6
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Data Retention")
        }

        // Retention period slider
        ColumnLayout {
            Kirigami.FormData.label: i18n("Keep data for:")
            enabled: historySwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: retentionSlider
                Layout.fillWidth: true
                from: 7
                to: 365
                stepSize: 1
                value: plasmoid.configuration.historyRetentionDays
            }

            QQC2.Label {
                text: {
                    var days = retentionSlider.value;
                    if (days >= 365) return i18n("1 year");
                    if (days >= 30) {
                        var months = Math.floor(days / 30);
                        var remainder = days % 30;
                        if (remainder > 0) {
                            return i18np("%1 month", "%1 months", months) + " " + i18np("%1 day", "%1 days", remainder);
                        }
                        return i18np("%1 month", "%1 months", months);
                    }
                    return i18np("%1 day", "%1 days", days);
                }
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        QQC2.Label {
            enabled: historySwitch.checked
            text: i18n("Data older than this will be automatically pruned daily.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Storage")
        }

        // Database size
        QQC2.Label {
            Kirigami.FormData.label: i18n("Database size:")
            text: formatBytes(historyDb.databaseSize())
        }

        // Providers with data
        QQC2.Label {
            Kirigami.FormData.label: i18n("Providers tracked:")
            text: {
                var providers = historyDb.getProviders();
                return providers.length > 0 ? providers.join(", ") : i18n("None");
            }
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Prune now button
        QQC2.Button {
            Kirigami.FormData.label: i18n("Maintenance:")
            text: i18n("Prune Old Data Now")
            icon.name: "edit-clear-history"
            enabled: historySwitch.checked
            onClicked: {
                historyDb.pruneOldData();
                // Force refresh of displayed size
                dbSizeRefreshTimer.restart();
            }
        }

        // Invisible timer to refresh the db size after pruning
        Timer {
            id: dbSizeRefreshTimer
            interval: 500
            repeat: false
            // Trigger a binding re-evaluation by toggling a dummy property
            onTriggered: historyPage.forceActiveFocus()
        }
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }
}
