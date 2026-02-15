import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

/**
 * Cost summary card showing aggregate cost across all enabled providers.
 */
ColumnLayout {
    id: costCard

    property var providers: []

    readonly property double totalCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.cost;
        }
        return total;
    }

    readonly property double totalDailyCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.dailyCost;
        }
        return total;
    }

    readonly property double totalMonthlyCost: {
        var total = 0;
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend && providers[i].backend.connected)
                total += providers[i].backend.monthlyCost;
        }
        return total;
    }

    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: costContent.implicitHeight + Kirigami.Units.largeSpacing * 2
        radius: Kirigami.Units.cornerRadius
        color: Qt.alpha(Kirigami.Theme.highlightColor, 0.08)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.highlightColor, 0.2)

        ColumnLayout {
            id: costContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true

                PlasmaExtras.Heading {
                    level: 4
                    text: i18n("Total Cost")
                }

                Item { Layout.fillWidth: true }

                PlasmaComponents.Label {
                    text: "$" + costCard.totalCost.toFixed(4)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                    color: {
                        if (costCard.totalCost > 50) return Kirigami.Theme.negativeTextColor;
                        if (costCard.totalCost > 20) return Kirigami.Theme.neutralTextColor;
                        return Kirigami.Theme.textColor;
                    }
                }
            }

            // Per-provider cost breakdown
            Repeater {
                model: costCard.providers

                RowLayout {
                    Layout.fillWidth: true
                    visible: modelData.enabled && modelData.backend && modelData.backend.connected && modelData.backend.cost > 0
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: modelData.color
                    }

                    PlasmaComponents.Label {
                        text: modelData.name
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }

                    Item { Layout.fillWidth: true }

                    PlasmaComponents.Label {
                        text: "$" + (modelData.backend?.cost ?? 0).toFixed(4)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            // Daily / Monthly summary
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: costCard.totalDailyCost > 0 || costCard.totalMonthlyCost > 0
            }

            RowLayout {
                Layout.fillWidth: true
                visible: costCard.totalDailyCost > 0 || costCard.totalMonthlyCost > 0
                spacing: Kirigami.Units.largeSpacing

                PlasmaComponents.Label {
                    visible: costCard.totalDailyCost > 0
                    text: i18n("Today: $%1", costCard.totalDailyCost.toFixed(2))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                PlasmaComponents.Label {
                    visible: costCard.totalMonthlyCost > 0
                    text: i18n("This month: $%1", costCard.totalMonthlyCost.toFixed(2))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }
            }
        }
    }
}
