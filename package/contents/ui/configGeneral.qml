import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: generalPage

    property alias cfg_refreshInterval: refreshSlider.value
    property alias cfg_compactDisplayMode: compactModeCombo.currentIndex

    Kirigami.FormLayout {
        anchors.fill: parent

        // Refresh interval
        ColumnLayout {
            Kirigami.FormData.label: i18n("Refresh interval:")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: refreshSlider
                Layout.fillWidth: true
                from: 60
                to: 1800
                stepSize: 60
                value: plasmoid.configuration.refreshInterval
            }

            QQC2.Label {
                text: {
                    var secs = refreshSlider.value;
                    if (secs >= 60) {
                        var mins = Math.floor(secs / 60);
                        return i18np("%1 minute", "%1 minutes", mins);
                    }
                    return i18np("%1 second", "%1 seconds", secs);
                }
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Panel Display")
        }

        // Compact display mode
        QQC2.ComboBox {
            id: compactModeCombo
            Kirigami.FormData.label: i18n("Show in panel:")
            model: [
                i18n("Icon only"),
                i18n("Total cost"),
                i18n("Active providers count")
            ]
            currentIndex: {
                switch (plasmoid.configuration.compactDisplayMode) {
                    case "cost": return 1;
                    case "count": return 2;
                    default: return 0;
                }
            }
            onCurrentIndexChanged: {
                switch (currentIndex) {
                    case 1: plasmoid.configuration.compactDisplayMode = "cost"; break;
                    case 2: plasmoid.configuration.compactDisplayMode = "count"; break;
                    default: plasmoid.configuration.compactDisplayMode = "icon"; break;
                }
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("About")
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Version:")
            text: "1.0.0"
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Description:")
            text: i18n("Monitor AI API token usage, rate limits, and costs")
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
