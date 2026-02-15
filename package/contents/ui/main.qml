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
        var allProviders = [
            { name: "OpenAI", backend: openaiBackend, enabled: plasmoid.configuration.openaiEnabled },
            { name: "Anthropic", backend: anthropicBackend, enabled: plasmoid.configuration.anthropicEnabled },
            { name: "Gemini", backend: googleBackend, enabled: plasmoid.configuration.googleEnabled },
            { name: "Mistral", backend: mistralBackend, enabled: plasmoid.configuration.mistralEnabled },
            { name: "DeepSeek", backend: deepseekBackend, enabled: plasmoid.configuration.deepseekEnabled },
            { name: "Groq", backend: groqBackend, enabled: plasmoid.configuration.groqEnabled },
            { name: "xAI", backend: xaiBackend, enabled: plasmoid.configuration.xaiEnabled }
        ];
        for (var i = 0; i < allProviders.length; i++) {
            var p = allProviders[i];
            if (p.enabled && p.backend.connected) {
                var info = p.name + ": ";
                if (p.backend.cost > 0)
                    info += "$" + p.backend.cost.toFixed(2) + " | ";
                info += p.backend.rateLimitRequestsRemaining + " req left";
                lines.push(info);
            }
        }
        return lines.length > 0 ? lines.join("\n") : i18n("Click to configure providers");
    }

    // Expose backends to child QML components
    property alias openai: openaiBackend
    property alias anthropic: anthropicBackend
    property alias google: googleBackend
    property alias mistral: mistralBackend
    property alias deepseek: deepseekBackend
    property alias groq: groqBackend
    property alias xai: xaiBackend
    property alias usageDb: usageDatabase

    // Notification cooldown tracking
    property var lastNotificationTimes: ({})

    // ── Secrets Manager (KWallet) ──
    SecretsManager {
        id: secrets

        onWalletOpenChanged: {
            if (walletOpen) {
                loadApiKeys();
            }
        }
    }

    // ── Usage Database (SQLite) ──
    UsageDatabase {
        id: usageDatabase
        enabled: plasmoid.configuration.historyEnabled
        retentionDays: plasmoid.configuration.historyRetentionDays
    }

    // ── C++ Provider Backends ──

    OpenAIProvider {
        id: openaiBackend
        model: plasmoid.configuration.openaiModel
        projectId: plasmoid.configuration.openaiProjectId
        customBaseUrl: plasmoid.configuration.openaiCustomBaseUrl
        dailyBudget: plasmoid.configuration.openaiDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.openaiMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.openaiNotificationsEnabled) {
                sendNotification(i18n("OpenAI Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("OpenAI", openaiBackend)
    }

    AnthropicProvider {
        id: anthropicBackend
        model: plasmoid.configuration.anthropicModel
        customBaseUrl: plasmoid.configuration.anthropicCustomBaseUrl
        dailyBudget: plasmoid.configuration.anthropicDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.anthropicMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.anthropicNotificationsEnabled) {
                sendNotification(i18n("Anthropic Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("Anthropic", anthropicBackend)
    }

    GoogleProvider {
        id: googleBackend
        model: plasmoid.configuration.googleModel
        customBaseUrl: plasmoid.configuration.googleCustomBaseUrl
        dailyBudget: plasmoid.configuration.googleDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.googleMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.googleNotificationsEnabled) {
                sendNotification(i18n("Google Gemini Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("Google", googleBackend)
    }

    MistralProvider {
        id: mistralBackend
        model: plasmoid.configuration.mistralModel
        customBaseUrl: plasmoid.configuration.mistralCustomBaseUrl
        dailyBudget: plasmoid.configuration.mistralDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.mistralMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.mistralNotificationsEnabled) {
                sendNotification(i18n("Mistral AI Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("Mistral", mistralBackend)
    }

    DeepSeekProvider {
        id: deepseekBackend
        model: plasmoid.configuration.deepseekModel
        customBaseUrl: plasmoid.configuration.deepseekCustomBaseUrl
        dailyBudget: plasmoid.configuration.deepseekDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.deepseekMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.deepseekNotificationsEnabled) {
                sendNotification(i18n("DeepSeek Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("DeepSeek", deepseekBackend)
    }

    GroqProvider {
        id: groqBackend
        model: plasmoid.configuration.groqModel
        customBaseUrl: plasmoid.configuration.groqCustomBaseUrl
        dailyBudget: plasmoid.configuration.groqDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.groqMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.groqNotificationsEnabled) {
                sendNotification(i18n("Groq Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("Groq", groqBackend)
    }

    XAIProvider {
        id: xaiBackend
        model: plasmoid.configuration.xaiModel
        customBaseUrl: plasmoid.configuration.xaiCustomBaseUrl
        dailyBudget: plasmoid.configuration.xaiDailyBudget / 100.0
        monthlyBudget: plasmoid.configuration.xaiMonthlyBudget / 100.0

        onQuotaWarning: function(provider, percent) {
            handleQuotaWarning(provider, percent);
        }
        onBudgetExceeded: function(provider, period, spent, budget) {
            handleBudgetExceeded(provider, period, spent, budget);
        }
        onProviderDisconnected: function(provider) {
            handleProviderDisconnected(provider);
        }
        onProviderReconnected: function(provider) {
            handleProviderReconnected(provider);
        }
        onErrorChanged: {
            if (error && plasmoid.configuration.notifyOnError
                && plasmoid.configuration.xaiNotificationsEnabled) {
                sendNotification(i18n("xAI Error"), error);
            }
        }
        onDataUpdated: recordProviderSnapshot("xAI", xaiBackend)
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

    Notification {
        id: budgetNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "budgetWarning"
        title: i18n("AI Usage Monitor - Budget")
        iconName: "wallet-open"
    }

    Notification {
        id: connectionNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "providerDisconnected"
        title: i18n("AI Usage Monitor")
        iconName: "network-disconnect"
    }

    // ── UI Representations ──

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // ── Refresh Timers ──

    // Global refresh timer (used when no per-provider interval is set)
    Timer {
        id: refreshTimer
        interval: plasmoid.configuration.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: refreshAll()
    }

    // Daily prune timer (runs once every 24h)
    Timer {
        id: pruneTimer
        interval: 24 * 60 * 60 * 1000 // 24 hours
        running: true
        repeat: true
        onTriggered: usageDatabase.pruneOldData()
    }

    // ── Context Menu Actions ──

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Refresh All")
            icon.name: "view-refresh"
            onTriggered: root.refreshAll()
        }
    ]

    // ── Helper: all provider info ──

    readonly property var allProviders: [
        { name: "OpenAI", backend: openaiBackend, enabled: plasmoid.configuration.openaiEnabled, color: "#10A37F" },
        { name: "Anthropic", backend: anthropicBackend, enabled: plasmoid.configuration.anthropicEnabled, color: "#D4A574" },
        { name: "Google Gemini", backend: googleBackend, enabled: plasmoid.configuration.googleEnabled, color: "#4285F4" },
        { name: "Mistral AI", backend: mistralBackend, enabled: plasmoid.configuration.mistralEnabled, color: "#FF7000" },
        { name: "DeepSeek", backend: deepseekBackend, enabled: plasmoid.configuration.deepseekEnabled, color: "#5B6EE1" },
        { name: "Groq", backend: groqBackend, enabled: plasmoid.configuration.groqEnabled, color: "#F55036" },
        { name: "xAI", backend: xaiBackend, enabled: plasmoid.configuration.xaiEnabled, color: "#1DA1F2" }
    ]

    readonly property int connectedCount: {
        var count = 0;
        for (var i = 0; i < allProviders.length; i++) {
            if (allProviders[i].enabled && allProviders[i].backend.connected) count++;
        }
        return count;
    }

    readonly property double totalCost: {
        var total = 0;
        for (var i = 0; i < allProviders.length; i++) {
            if (allProviders[i].enabled && allProviders[i].backend.connected)
                total += allProviders[i].backend.cost;
        }
        return total;
    }

    // ── Functions ──

    function refreshAll() {
        var providers = [
            { enabled: plasmoid.configuration.openaiEnabled, backend: openaiBackend },
            { enabled: plasmoid.configuration.anthropicEnabled, backend: anthropicBackend },
            { enabled: plasmoid.configuration.googleEnabled, backend: googleBackend },
            { enabled: plasmoid.configuration.mistralEnabled, backend: mistralBackend },
            { enabled: plasmoid.configuration.deepseekEnabled, backend: deepseekBackend },
            { enabled: plasmoid.configuration.groqEnabled, backend: groqBackend },
            { enabled: plasmoid.configuration.xaiEnabled, backend: xaiBackend }
        ];
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled && providers[i].backend.hasApiKey()) {
                providers[i].backend.refresh();
            }
        }
    }

    function loadApiKeys() {
        var providers = [
            { name: "openai", enabled: plasmoid.configuration.openaiEnabled, backend: openaiBackend },
            { name: "anthropic", enabled: plasmoid.configuration.anthropicEnabled, backend: anthropicBackend },
            { name: "google", enabled: plasmoid.configuration.googleEnabled, backend: googleBackend },
            { name: "mistral", enabled: plasmoid.configuration.mistralEnabled, backend: mistralBackend },
            { name: "deepseek", enabled: plasmoid.configuration.deepseekEnabled, backend: deepseekBackend },
            { name: "groq", enabled: plasmoid.configuration.groqEnabled, backend: groqBackend },
            { name: "xai", enabled: plasmoid.configuration.xaiEnabled, backend: xaiBackend }
        ];
        for (var i = 0; i < providers.length; i++) {
            if (providers[i].enabled) {
                var key = secrets.getKey(providers[i].name);
                if (key) providers[i].backend.setApiKey(key);
            }
        }

        // Trigger initial refresh after loading keys
        refreshAll();
    }

    function recordProviderSnapshot(providerName, backend) {
        if (!usageDatabase.enabled) return;
        usageDatabase.recordSnapshot(
            providerName,
            backend.inputTokens,
            backend.outputTokens,
            backend.requestCount,
            backend.cost,
            backend.dailyCost,
            backend.monthlyCost,
            backend.rateLimitRequests,
            backend.rateLimitRequestsRemaining,
            backend.rateLimitTokens,
            backend.rateLimitTokensRemaining
        );
    }

    function canNotify(eventKey) {
        var cooldown = plasmoid.configuration.notificationCooldownMinutes * 60 * 1000;
        var now = Date.now();
        var last = lastNotificationTimes[eventKey] || 0;
        if (now - last < cooldown) return false;

        // Check DND
        var dndStart = plasmoid.configuration.dndStartHour;
        var dndEnd = plasmoid.configuration.dndEndHour;
        if (dndStart >= 0 && dndEnd >= 0) {
            var hour = new Date().getHours();
            if (dndStart < dndEnd) {
                if (hour >= dndStart && hour < dndEnd) return false;
            } else {
                // Overnight DND (e.g., 22:00 - 07:00)
                if (hour >= dndStart || hour < dndEnd) return false;
            }
        }

        lastNotificationTimes[eventKey] = now;
        return true;
    }

    function handleQuotaWarning(provider, percentUsed) {
        if (!plasmoid.configuration.alertsEnabled) return;
        if (!canNotify("quota_" + provider)) return;

        // Record event in database
        usageDatabase.recordRateLimitEvent(provider,
            percentUsed >= plasmoid.configuration.criticalThreshold ? "critical" : "warning",
            percentUsed);

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

    function handleBudgetExceeded(provider, period, spent, budget) {
        if (!plasmoid.configuration.alertsEnabled) return;
        if (!plasmoid.configuration.notifyOnBudgetWarning) return;
        if (!canNotify("budget_" + provider + "_" + period)) return;

        budgetNotification.text = i18n("%1: %2 budget exceeded! $%3 / $%4",
            provider, period, spent.toFixed(2), budget.toFixed(2));
        budgetNotification.urgency = Notification.CriticalUrgency;
        budgetNotification.sendEvent();
    }

    function handleProviderDisconnected(provider) {
        if (!plasmoid.configuration.notifyOnDisconnect) return;
        if (!canNotify("disconnect_" + provider)) return;

        connectionNotification.eventId = "providerDisconnected";
        connectionNotification.iconName = "network-disconnect";
        connectionNotification.text = i18n("%1 has disconnected", provider);
        connectionNotification.urgency = Notification.NormalUrgency;
        connectionNotification.sendEvent();
    }

    function handleProviderReconnected(provider) {
        if (!plasmoid.configuration.notifyOnReconnect) return;
        if (!canNotify("reconnect_" + provider)) return;

        connectionNotification.eventId = "providerReconnected";
        connectionNotification.iconName = "network-connect";
        connectionNotification.text = i18n("%1 has reconnected", provider);
        connectionNotification.urgency = Notification.LowUrgency;
        connectionNotification.sendEvent();
    }

    function sendNotification(title, message) {
        if (!canNotify("error_" + title)) return;
        errorNotification.title = title;
        errorNotification.text = message;
        errorNotification.sendEvent();
    }

    // ── Lifecycle ──

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadApiKeys();
        }
        // Initial prune of old data
        usageDatabase.pruneOldData();
    }

    // React to config changes
    Connections {
        target: plasmoid.configuration

        function onOpenaiEnabledChanged() { loadApiKeys(); }
        function onAnthropicEnabledChanged() { loadApiKeys(); }
        function onGoogleEnabledChanged() { loadApiKeys(); }
        function onMistralEnabledChanged() { loadApiKeys(); }
        function onDeepseekEnabledChanged() { loadApiKeys(); }
        function onGroqEnabledChanged() { loadApiKeys(); }
        function onXaiEnabledChanged() { loadApiKeys(); }

        function onOpenaiModelChanged() { openaiBackend.model = plasmoid.configuration.openaiModel; }
        function onAnthropicModelChanged() { anthropicBackend.model = plasmoid.configuration.anthropicModel; }
        function onGoogleModelChanged() { googleBackend.model = plasmoid.configuration.googleModel; }
        function onMistralModelChanged() { mistralBackend.model = plasmoid.configuration.mistralModel; }
        function onDeepseekModelChanged() { deepseekBackend.model = plasmoid.configuration.deepseekModel; }
        function onGroqModelChanged() { groqBackend.model = plasmoid.configuration.groqModel; }
        function onXaiModelChanged() { xaiBackend.model = plasmoid.configuration.xaiModel; }

        function onRefreshIntervalChanged() {
            refreshTimer.interval = plasmoid.configuration.refreshInterval * 1000;
        }
    }
}
