import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmaExtras.Representation {
    id: fullRoot

    implicitWidth: Kirigami.Units.gridUnit * 22
    implicitHeight: Kirigami.Units.gridUnit * 24

    // Access backends via QML dynamic scoping to root PlasmoidItem (id: root in main.qml)

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
                onClicked: {
                    root.refreshAll();
                }
                PlasmaComponents.ToolTip { text: i18n("Refresh all providers") }
            }

            PlasmaComponents.ToolButton {
                icon.name: "configure"
                onClicked: plasmoid.internalAction("configure").trigger()
                PlasmaComponents.ToolTip { text: i18n("Configure...") }
            }
        }
    }

    // Main content
    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

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

        // Scrollable list of provider cards
        PlasmaComponents.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: hasAnyProvider()

            contentItem: Flickable {
                contentHeight: providerColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: providerColumn
                    width: parent.width
                    spacing: Kirigami.Units.mediumSpacing

                    // OpenAI Card
                    ProviderCard {
                        Layout.fillWidth: true
                        visible: plasmoid.configuration.openaiEnabled
                        providerName: "OpenAI"
                        providerIcon: "globe" // fallback system icon
                        providerColor: "#10A37F"
                        backend: root.openai ?? null
                        showCost: true
                        showUsage: true
                    }

                    // Anthropic Card
                    ProviderCard {
                        Layout.fillWidth: true
                        visible: plasmoid.configuration.anthropicEnabled
                        providerName: "Anthropic"
                        providerIcon: "globe"
                        providerColor: "#D4A574"
                        backend: root.anthropic ?? null
                        showCost: false
                        showUsage: false
                    }

                    // Google Gemini Card
                    ProviderCard {
                        Layout.fillWidth: true
                        visible: plasmoid.configuration.googleEnabled
                        providerName: "Google Gemini"
                        providerIcon: "globe"
                        providerColor: "#4285F4"
                        backend: root.google ?? null
                        showCost: false
                        showUsage: false
                    }

                    // Bottom spacer
                    Item { Layout.fillHeight: true }
                }
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

    function hasAnyProvider() {
        return plasmoid.configuration.openaiEnabled
            || plasmoid.configuration.anthropicEnabled
            || plasmoid.configuration.googleEnabled;
    }
}
