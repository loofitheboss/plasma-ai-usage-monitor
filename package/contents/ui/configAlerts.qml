import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: alertsPage

    property alias cfg_alertsEnabled: alertsSwitch.checked
    property alias cfg_warningThreshold: warningSlider.value
    property alias cfg_criticalThreshold: criticalSlider.value
    property alias cfg_notifyOnError: errorNotifySwitch.checked

    Kirigami.FormLayout {
        anchors.fill: parent

        // Master toggle
        QQC2.Switch {
            id: alertsSwitch
            Kirigami.FormData.label: i18n("Enable alerts:")
            checked: plasmoid.configuration.alertsEnabled
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Thresholds")
        }

        // Warning threshold
        ColumnLayout {
            Kirigami.FormData.label: i18n("Warning threshold:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: warningSlider
                Layout.fillWidth: true
                from: 50
                to: 95
                stepSize: 5
                value: plasmoid.configuration.warningThreshold

                // Ensure warning < critical
                onValueChanged: {
                    if (value >= criticalSlider.value) {
                        value = criticalSlider.value - 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", warningSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows yellow warning indicator and optional notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Critical threshold
        ColumnLayout {
            Kirigami.FormData.label: i18n("Critical threshold:")
            enabled: alertsSwitch.checked
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                id: criticalSlider
                Layout.fillWidth: true
                from: 60
                to: 100
                stepSize: 5
                value: plasmoid.configuration.criticalThreshold

                onValueChanged: {
                    if (value <= warningSlider.value) {
                        value = warningSlider.value + 5;
                    }
                }
            }

            QQC2.Label {
                text: i18n("%1% of rate limit used", criticalSlider.value)
                opacity: 0.7
                Layout.alignment: Qt.AlignHCenter
            }

            QQC2.Label {
                text: i18n("Shows red critical indicator and urgent notification")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.5
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Notification Types")
        }

        // Error notifications
        QQC2.Switch {
            id: errorNotifySwitch
            Kirigami.FormData.label: i18n("Notify on API errors:")
            enabled: alertsSwitch.checked
            checked: plasmoid.configuration.notifyOnError
        }

        QQC2.Label {
            text: i18n("Send a KDE notification when an API call fails (authentication errors, network issues, etc.)")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.5
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        // Preview section
        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Preview")
        }

        // Visual preview of what each threshold looks like
        RowLayout {
            Kirigami.FormData.label: i18n("Status colors:")
            spacing: Kirigami.Units.largeSpacing

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: Kirigami.Theme.positiveTextColor
                }
                QQC2.Label {
                    text: i18n("OK")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: Kirigami.Theme.neutralTextColor
                }
                QQC2.Label {
                    text: i18n("Warning")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: Kirigami.Theme.negativeTextColor
                }
                QQC2.Label {
                    text: i18n("Critical")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }
        }
    }
}
