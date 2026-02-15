import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

MouseArea {
    id: compactRoot

    // Access the PlasmoidItem (id: root in main.qml) through QML dynamic scoping.
    // The backends are exposed as root.openai, root.anthropic, root.google.
    readonly property bool hasWarning: {
        var providers = [root.openai, root.anthropic, root.google];
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.connected && p.rateLimitRequests > 0) {
                var usedPercent = ((p.rateLimitRequests - p.rateLimitRequestsRemaining) / p.rateLimitRequests) * 100;
                if (usedPercent >= plasmoid.configuration.warningThreshold) return true;
            }
        }
        return false;
    }
    readonly property bool hasCritical: {
        var providers = [root.openai, root.anthropic, root.google];
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
            if (p && p.connected && p.rateLimitRequests > 0) {
                var usedPercent = ((p.rateLimitRequests - p.rateLimitRequestsRemaining) / p.rateLimitRequests) * 100;
                if (usedPercent >= plasmoid.configuration.criticalThreshold) return true;
            }
        }
        return false;
    }
    readonly property bool anyConnected: {
        return (root.openai?.connected ?? false)
            || (root.anthropic?.connected ?? false)
            || (root.google?.connected ?? false);
    }
    readonly property bool anyLoading: {
        return (root.openai?.loading ?? false)
            || (root.anthropic?.loading ?? false)
            || (root.google?.loading ?? false);
    }

    hoverEnabled: true
    onClicked: plasmoid.activated()

    Kirigami.Icon {
        id: mainIcon
        anchors.fill: parent
        source: "cpu"
        active: compactRoot.containsMouse

        // Overlay badge for status indication
        Rectangle {
            id: statusBadge
            visible: compactRoot.anyConnected
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Kirigami.Units.smallSpacing * 3
            height: width
            radius: width / 2
            color: {
                if (compactRoot.hasCritical) return Kirigami.Theme.negativeTextColor;
                if (compactRoot.hasWarning) return Kirigami.Theme.neutralTextColor;
                return Kirigami.Theme.positiveTextColor;
            }
            border.width: 1
            border.color: Kirigami.Theme.backgroundColor
        }
    }

    // Spinning indicator when loading
    PlasmaComponents.BusyIndicator {
        anchors.fill: parent
        visible: compactRoot.anyLoading
        running: visible
    }
}
