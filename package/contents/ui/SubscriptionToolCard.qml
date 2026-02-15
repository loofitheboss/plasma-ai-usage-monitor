import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

/**
 * Card component for displaying subscription tool usage (Claude Code, Codex, Copilot).
 * Shows usage count vs limit with progress bars and time-until-reset countdown.
 */
ColumnLayout {
    id: toolCard

    required property string toolName
    required property string toolIcon
    required property string toolColor
    required property var monitor
    property bool collapsed: false

    spacing: 0

    // Card background
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: toolContent.implicitHeight + Kirigami.Units.largeSpacing * 2
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
            if (!toolCard.monitor) status = i18n("not available");
            else if (!toolCard.monitor.installed) status = i18n("not installed");
            else if (toolCard.monitor.limitReached) status = i18n("limit reached");
            else status = i18n("active");

            var desc = toolCard.toolName + ", " + status;
            if (toolCard.monitor && toolCard.monitor.usageLimit > 0) {
                desc += ", " + toolCard.monitor.usageCount + "/" + toolCard.monitor.usageLimit;
            }
            return desc;
        }

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
        }

        clip: true

        ColumnLayout {
            id: toolContent
            anchors {
                fill: parent
                margins: Kirigami.Units.largeSpacing
            }
            spacing: Kirigami.Units.mediumSpacing

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Tool color indicator
                Rectangle {
                    width: 4
                    Layout.preferredHeight: toolLabel.implicitHeight
                    radius: 2
                    color: toolCard.toolColor
                }

                Kirigami.Icon {
                    source: toolCard.toolIcon
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                }

                PlasmaExtras.Heading {
                    id: toolLabel
                    level: 4
                    text: toolCard.toolName
                    Layout.fillWidth: true
                }

                // Plan tier badge
                Rectangle {
                    visible: (toolCard.monitor?.planTier ?? "") !== ""
                    width: tierLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                    height: tierLabel.implicitHeight + Kirigami.Units.smallSpacing
                    radius: height / 2
                    color: Qt.alpha(toolCard.toolColor, 0.2)

                    PlasmaComponents.Label {
                        id: tierLabel
                        anchors.centerIn: parent
                        text: toolCard.monitor?.planTier ?? ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        color: toolCard.toolColor
                    }
                }

                // Status indicator
                PlasmaComponents.Label {
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    text: {
                        if (!toolCard.monitor) return i18n("N/A");
                        if (!toolCard.monitor.installed) return i18n("Not Installed");
                        if (toolCard.monitor.limitReached) return i18n("Limit Reached");
                        return i18n("Active");
                    }
                    color: {
                        if (!toolCard.monitor) return Kirigami.Theme.disabledTextColor;
                        if (!toolCard.monitor.installed) return Kirigami.Theme.disabledTextColor;
                        if (toolCard.monitor.limitReached) return Kirigami.Theme.negativeTextColor;
                        return Kirigami.Theme.positiveTextColor;
                    }
                }

                // Compact usage when collapsed
                PlasmaComponents.Label {
                    visible: toolCard.collapsed && (toolCard.monitor?.usageLimit ?? 0) > 0
                    text: (toolCard.monitor?.usageCount ?? 0) + "/" + (toolCard.monitor?.usageLimit ?? 0)
                    font.bold: true
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.7
                }

                // Collapse/expand toggle
                PlasmaComponents.ToolButton {
                    icon.name: toolCard.collapsed ? "arrow-down" : "arrow-up"
                    display: PlasmaComponents.AbstractButton.IconOnly
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    onClicked: toolCard.collapsed = !toolCard.collapsed
                    PlasmaComponents.ToolTip { text: toolCard.collapsed ? i18n("Expand") : i18n("Collapse") }
                }
            }

            // Not installed message
            PlasmaComponents.Label {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && !(toolCard.monitor?.installed ?? false)
                text: i18n("Tool not detected on this system")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.italic: true
                opacity: 0.6
                wrapMode: Text.WordWrap
            }

            // Separator
            Kirigami.Separator {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
            }

            // Primary usage bar
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                         && (toolCard.monitor?.usageLimit ?? 0) > 0
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        text: toolCard.monitor?.periodLabel ?? ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.usageCount ?? 0) + " / " + (toolCard.monitor?.usageLimit ?? 0)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    from: 0
                    to: toolCard.monitor?.usageLimit ?? 1
                    value: Math.min(toolCard.monitor?.usageCount ?? 0, toolCard.monitor?.usageLimit ?? 1)

                    background: Rectangle {
                        implicitHeight: 6
                        radius: 3
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }

                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 6
                        radius: 3
                        color: usageColor(toolCard.monitor?.percentUsed ?? 0)

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                    }
                }

                // Percentage text
                PlasmaComponents.Label {
                    text: Math.round(toolCard.monitor?.percentUsed ?? 0) + "% " + i18n("used")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.5
                    color: usageColor(toolCard.monitor?.percentUsed ?? 0)
                }
            }

            // Secondary usage bar (e.g., weekly for Claude Code)
            ColumnLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                         && (toolCard.monitor?.hasSecondaryLimit ?? false)
                         && (toolCard.monitor?.secondaryUsageLimit ?? 0) > 0
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true

                    PlasmaComponents.Label {
                        text: toolCard.monitor?.secondaryPeriodLabel ?? ""
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        opacity: 0.7
                    }
                    Item { Layout.fillWidth: true }
                    PlasmaComponents.Label {
                        text: (toolCard.monitor?.secondaryUsageCount ?? 0) + " / " + (toolCard.monitor?.secondaryUsageLimit ?? 0)
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                        font.bold: true
                    }
                }

                QQC2.ProgressBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    from: 0
                    to: toolCard.monitor?.secondaryUsageLimit ?? 1
                    value: Math.min(toolCard.monitor?.secondaryUsageCount ?? 0, toolCard.monitor?.secondaryUsageLimit ?? 1)

                    background: Rectangle {
                        implicitHeight: 6
                        radius: 3
                        color: Qt.alpha(Kirigami.Theme.textColor, 0.1)
                    }

                    contentItem: Rectangle {
                        width: parent.visualPosition * parent.width
                        height: 6
                        radius: 3
                        color: usageColor(toolCard.monitor?.secondaryPercentUsed ?? 0)

                        Behavior on width {
                            NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
                        }
                        Behavior on color {
                            ColorAnimation { duration: 300 }
                        }
                    }
                }
            }

            // Time until reset
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    source: "chronometer"
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    opacity: 0.6
                }

                PlasmaComponents.Label {
                    text: i18n("Resets in: %1", toolCard.monitor?.timeUntilReset ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.6
                }

                Item { Layout.fillWidth: true }

                // Last activity
                PlasmaComponents.Label {
                    visible: toolCard.monitor?.lastActivity?.getTime() > 0
                    text: i18n("Last: %1", formatRelativeTime(toolCard.monitor?.lastActivity))
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    opacity: 0.4
                }
            }

            // Limit reached warning
            Rectangle {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.limitReached ?? false)
                height: limitWarningLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
                radius: Kirigami.Units.cornerRadius
                color: Qt.alpha(Kirigami.Theme.negativeBackgroundColor, 0.3)
                border.width: 1
                border.color: Qt.alpha(Kirigami.Theme.negativeTextColor, 0.3)

                PlasmaComponents.Label {
                    id: limitWarningLabel
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    text: i18n("Usage limit reached! Resets in %1.", toolCard.monitor?.timeUntilReset ?? "")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    color: Kirigami.Theme.negativeTextColor
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            // Manual increment button (for tools where auto-detection isn't perfect)
            RowLayout {
                Layout.fillWidth: true
                visible: !toolCard.collapsed && (toolCard.monitor?.installed ?? false)
                spacing: Kirigami.Units.smallSpacing

                Item { Layout.fillWidth: true }

                PlasmaComponents.ToolButton {
                    icon.name: "list-add"
                    text: i18n("+1 Usage")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    onClicked: {
                        if (toolCard.monitor) toolCard.monitor.incrementUsage();
                    }
                    PlasmaComponents.ToolTip { text: i18n("Manually record one usage") }
                }

                PlasmaComponents.ToolButton {
                    icon.name: "edit-clear"
                    text: i18n("Reset")
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    onClicked: {
                        if (toolCard.monitor) toolCard.monitor.resetUsage();
                    }
                    PlasmaComponents.ToolTip { text: i18n("Reset usage counter for current period") }
                }
            }
        }
    }

    // ── Helper functions ──

    function usageColor(percent) {
        if (percent >= 95) return Kirigami.Theme.negativeTextColor;
        if (percent >= 80) return "#FF8C00"; // orange
        if (percent >= 50) return Kirigami.Theme.neutralTextColor;
        return Kirigami.Theme.positiveTextColor;
    }

    function formatRelativeTime(dateTime) {
        if (!dateTime) return "";
        var now = new Date();
        var diff = Math.floor((now - dateTime) / 1000);
        if (diff < 5) return i18n("just now");
        if (diff < 60) return i18n("%1s ago", diff);
        if (diff < 3600) return i18n("%1m ago", Math.floor(diff / 60));
        if (diff < 86400) return i18n("%1h ago", Math.floor(diff / 3600));
        return Qt.formatTime(dateTime, "hh:mm:ss");
    }
}
