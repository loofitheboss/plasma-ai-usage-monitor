import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.notification
import com.github.loofi.aiusagemonitor 1.0

PlasmoidItem {
    id: root

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 12

    toolTipMainText: i18n("AI Usage Monitor")
    toolTipSubText: {
        var lines = [];
        if (openaiBackend.connected)
            lines.push("OpenAI: $" + openaiBackend.cost.toFixed(2)
                        + " | " + openaiBackend.rateLimitRequestsRemaining + " req left");
        if (anthropicBackend.connected)
            lines.push("Anthropic: " + anthropicBackend.rateLimitRequestsRemaining
                        + "/" + anthropicBackend.rateLimitRequests + " req/min");
        if (googleBackend.connected)
            lines.push("Gemini: Connected");
        return lines.length > 0 ? lines.join("\n") : i18n("Click to configure providers");
    }

    // Expose backends to child QML components
    property alias openai: openaiBackend
    property alias anthropic: anthropicBackend
    property alias google: googleBackend

    // ── Secrets Manager (KWallet) ──
    SecretsManager {
        id: secrets

        onWalletOpenChanged: {
            if (walletOpen) {
                loadApiKeys();
            }
        }
    }

    // ── C++ Provider Backends ──

    OpenAIProvider {
        id: openaiBackend
        model: plasmoid.configuration.openaiModel
        projectId: plasmoid.configuration.openaiProjectId

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError) {
                sendNotification(i18n("OpenAI Error"), error);
            }
        }
    }

    AnthropicProvider {
        id: anthropicBackend
        model: plasmoid.configuration.anthropicModel

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError) {
                sendNotification(i18n("Anthropic Error"), error);
            }
        }
    }

    GoogleProvider {
        id: googleBackend
        model: plasmoid.configuration.googleModel

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError) {
                sendNotification(i18n("Google Gemini Error"), error);
            }
        }
    }

    // ── KDE Notifications ──

    Notification {
        id: warningNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "quotaWarning"
        title: i18n("AI Usage Monitor")
        iconName: "dialog-warning"
    }

    Notification {
        id: errorNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "apiError"
        title: i18n("AI Usage Monitor")
        iconName: "dialog-error"
    }

    // ── UI Representations ──

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // ── Refresh Timer ──

    Timer {
        id: refreshTimer
        interval: plasmoid.configuration.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: refreshAll()
    }

    // ── Context Menu Actions ──

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh All")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        }
    ]

    // ── Functions ──

    function refreshAll() {
        if (plasmoid.configuration.openaiEnabled && openaiBackend.hasApiKey()) {
            openaiBackend.refresh();
        }
        if (plasmoid.configuration.anthropicEnabled && anthropicBackend.hasApiKey()) {
            anthropicBackend.refresh();
        }
        if (plasmoid.configuration.googleEnabled && googleBackend.hasApiKey()) {
            googleBackend.refresh();
        }
    }

    function loadApiKeys() {
        // Load API keys from KWallet into the C++ backends
        if (plasmoid.configuration.openaiEnabled) {
            var openaiKey = secrets.getKey("openai");
            if (openaiKey) openaiBackend.setApiKey(openaiKey);
        }
        if (plasmoid.configuration.anthropicEnabled) {
            var anthropicKey = secrets.getKey("anthropic");
            if (anthropicKey) anthropicBackend.setApiKey(anthropicKey);
        }
        if (plasmoid.configuration.googleEnabled) {
            var googleKey = secrets.getKey("google");
            if (googleKey) googleBackend.setApiKey(googleKey);
        }

        // Trigger initial refresh after loading keys
        refreshAll();
    }

    function handleQuotaWarning(provider, percentUsed) {
        if (!plasmoid.configuration.alertsEnabled) return;

        var isCritical = percentUsed >= plasmoid.configuration.criticalThreshold;
        var isWarning = percentUsed >= plasmoid.configuration.warningThreshold;

        if (isCritical) {
            warningNotification.text = i18n("%1: CRITICAL - %2% of rate limit used!", provider, percentUsed);
            warningNotification.urgency = Notification.CriticalUrgency;
            warningNotification.sendEvent();
        } else if (isWarning) {
            warningNotification.text = i18n("%1: Warning - %2% of rate limit used", provider, percentUsed);
            warningNotification.urgency = Notification.NormalUrgency;
            warningNotification.sendEvent();
        }
    }

    function sendNotification(title, message) {
        errorNotification.title = title;
        errorNotification.text = message;
        errorNotification.sendEvent();
    }

    // ── Lifecycle ──

    Component.onCompleted: {
        // If wallet is already open by the time QML loads, load keys immediately
        if (secrets.walletOpen) {
            loadApiKeys();
        }
    }

    // React to config changes
    Connections {
        target: plasmoid.configuration

        function onOpenaiEnabledChanged() { loadApiKeys(); }
        function onAnthropicEnabledChanged() { loadApiKeys(); }
        function onGoogleEnabledChanged() { loadApiKeys(); }
        function onOpenaiModelChanged() { openaiBackend.model = plasmoid.configuration.openaiModel; }
        function onAnthropicModelChanged() { anthropicBackend.model = plasmoid.configuration.anthropicModel; }
        function onGoogleModelChanged() { googleBackend.model = plasmoid.configuration.googleModel; }
        function onRefreshIntervalChanged() { refreshTimer.interval = plasmoid.configuration.refreshInterval * 1000; }
    }
}
