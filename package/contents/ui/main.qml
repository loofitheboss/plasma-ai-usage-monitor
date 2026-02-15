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
        var providers = root.allProviders;
        for (var i = 0; i < providers.length; i++) {
            var p = providers[i];
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

    // Subscription tool monitors
    property alias claudeCode: claudeCodeMonitor
    property alias codexCli: codexCliMonitor
    property alias copilot: copilotMonitor

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

    // ── Subscription Tool Monitors ──

    // Browser cookie extractor for sync
    BrowserCookieExtractor {
        id: browserCookies
        browserType: plasmoid.configuration.browserSyncBrowser
    }

    // Browser sync timer
    Timer {
        id: browserSyncTimer
        interval: Math.max(60, plasmoid.configuration.browserSyncInterval) * 1000
        running: plasmoid.configuration.browserSyncEnabled
        repeat: true
        onTriggered: performBrowserSync()
    }

    ClaudeCodeMonitor {
        id: claudeCodeMonitor
        enabled: plasmoid.configuration.claudeCodeEnabled
        usageLimit: plasmoid.configuration.claudeCodeCustomLimit

        Component.onCompleted: {
            checkToolInstalled();
            syncEnabled = Qt.binding(function() { return plasmoid.configuration.browserSyncEnabled; });
            // Set plan from config index
            var plans = availablePlans();
            var idx = plasmoid.configuration.claudeCodePlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) usageLimit = defaultLimitForPlan(plans[idx]);
                if (hasSecondaryLimit) secondaryUsageLimit = defaultSecondaryLimitForPlan(plans[idx]);
            }
        }

        onLimitWarning: function(tool, percent) {
            handleToolLimitWarning(tool, percent);
        }
        onLimitReached: function(tool) {
            handleToolLimitReached(tool);
        }
        onUsageUpdated: {
            recordToolUsageSnapshot(claudeCodeMonitor);
        }
    }

    CodexCliMonitor {
        id: codexCliMonitor
        enabled: plasmoid.configuration.codexEnabled
        usageLimit: plasmoid.configuration.codexCustomLimit

        Component.onCompleted: {
            checkToolInstalled();
            syncEnabled = Qt.binding(function() { return plasmoid.configuration.browserSyncEnabled; });
            var plans = availablePlans();
            var idx = plasmoid.configuration.codexPlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) usageLimit = defaultLimitForPlan(plans[idx]);
                if (hasSecondaryLimit) secondaryUsageLimit = defaultSecondaryLimitForPlan(plans[idx]);
            }
        }

        onLimitWarning: function(tool, percent) {
            handleToolLimitWarning(tool, percent);
        }
        onLimitReached: function(tool) {
            handleToolLimitReached(tool);
        }
        onUsageUpdated: {
            recordToolUsageSnapshot(codexCliMonitor);
        }
    }

    CopilotMonitor {
        id: copilotMonitor
        enabled: plasmoid.configuration.copilotEnabled
        usageLimit: plasmoid.configuration.copilotCustomLimit
        orgName: plasmoid.configuration.copilotOrgName

        Component.onCompleted: {
            checkToolInstalled();
            var plans = availablePlans();
            var idx = plasmoid.configuration.copilotPlan;
            if (idx >= 0 && idx < plans.length) {
                planTier = plans[idx];
                if (usageLimit === 0) usageLimit = defaultLimitForPlan(plans[idx]);
            }
            // Load GitHub token from KWallet
            if (secrets.walletOpen && secrets.hasKey("copilot_github")) {
                githubToken = secrets.getKey("copilot_github");
            }
        }

        onLimitWarning: function(tool, percent) {
            handleToolLimitWarning(tool, percent);
        }
        onLimitReached: function(tool) {
            handleToolLimitReached(tool);
        }
        onUsageUpdated: {
            recordToolUsageSnapshot(copilotMonitor);
        }
    }

    // ── Subscription Notification ──

    Notification {
        id: subscriptionNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "quotaWarning"
        title: i18n("AI Usage Monitor - Subscription")
        iconName: "dialog-warning"
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

    Notification {
        id: updateNotification
        componentName: "plasma_applet_com.github.loofi.aiusagemonitor"
        eventId: "updateAvailable"
        title: i18n("AI Usage Monitor - Update Available")
        iconName: "update-none"
    }

    // ── Update Checker ──

    UpdateChecker {
        id: updateChecker
        currentVersion: "2.2.0"
        checkIntervalHours: plasmoid.configuration.updateCheckInterval || 12

        onUpdateAvailable: function(latestVersion, releaseUrl) {
            if (!plasmoid.configuration.notifyOnUpdate) return;
            updateNotification.text = i18n("Version %1 is available! Visit %2 to update.",
                                           latestVersion, releaseUrl);
            updateNotification.sendEvent();
        }
    }

    // ── UI Representations ──

    compactRepresentation: CompactRepresentation {}
    fullRepresentation: FullRepresentation {}

    // ── Refresh Timers ──

    // Helper to get effective interval for a provider (0 = use global)
    function effectiveInterval(providerInterval) {
        return (providerInterval > 0 ? providerInterval : plasmoid.configuration.refreshInterval) * 1000;
    }

    // Per-provider refresh timers
    Timer {
        id: openaiRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.openaiRefreshInterval)
        running: plasmoid.configuration.openaiEnabled
        repeat: true
        onTriggered: {
            if (openaiBackend.hasApiKey()) openaiBackend.refresh();
        }
    }
    Timer {
        id: anthropicRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.anthropicRefreshInterval)
        running: plasmoid.configuration.anthropicEnabled
        repeat: true
        onTriggered: {
            if (anthropicBackend.hasApiKey()) anthropicBackend.refresh();
        }
    }
    Timer {
        id: googleRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.googleRefreshInterval)
        running: plasmoid.configuration.googleEnabled
        repeat: true
        onTriggered: {
            if (googleBackend.hasApiKey()) googleBackend.refresh();
        }
    }
    Timer {
        id: mistralRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.mistralRefreshInterval)
        running: plasmoid.configuration.mistralEnabled
        repeat: true
        onTriggered: {
            if (mistralBackend.hasApiKey()) mistralBackend.refresh();
        }
    }
    Timer {
        id: deepseekRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.deepseekRefreshInterval)
        running: plasmoid.configuration.deepseekEnabled
        repeat: true
        onTriggered: {
            if (deepseekBackend.hasApiKey()) deepseekBackend.refresh();
        }
    }
    Timer {
        id: groqRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.groqRefreshInterval)
        running: plasmoid.configuration.groqEnabled
        repeat: true
        onTriggered: {
            if (groqBackend.hasApiKey()) groqBackend.refresh();
        }
    }
    Timer {
        id: xaiRefreshTimer
        interval: effectiveInterval(plasmoid.configuration.xaiRefreshInterval)
        running: plasmoid.configuration.xaiEnabled
        repeat: true
        onTriggered: {
            if (xaiBackend.hasApiKey()) xaiBackend.refresh();
        }
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
        { name: "OpenAI", configKey: "openai", backend: openaiBackend, enabled: plasmoid.configuration.openaiEnabled, color: "#10A37F" },
        { name: "Anthropic", configKey: "anthropic", backend: anthropicBackend, enabled: plasmoid.configuration.anthropicEnabled, color: "#D4A574" },
        { name: "Google Gemini", configKey: "google", backend: googleBackend, enabled: plasmoid.configuration.googleEnabled, color: "#4285F4" },
        { name: "Mistral AI", configKey: "mistral", backend: mistralBackend, enabled: plasmoid.configuration.mistralEnabled, color: "#FF7000" },
        { name: "DeepSeek", configKey: "deepseek", backend: deepseekBackend, enabled: plasmoid.configuration.deepseekEnabled, color: "#5B6EE1" },
        { name: "Groq", configKey: "groq", backend: groqBackend, enabled: plasmoid.configuration.groqEnabled, color: "#F55036" },
        { name: "xAI / Grok", configKey: "xai", backend: xaiBackend, enabled: plasmoid.configuration.xaiEnabled, color: "#1DA1F2" }
    ]

    readonly property var allSubscriptionTools: [
        { name: "Claude Code", monitor: claudeCodeMonitor, enabled: plasmoid.configuration.claudeCodeEnabled, notify: plasmoid.configuration.claudeCodeNotifications },
        { name: "Codex CLI", monitor: codexCliMonitor, enabled: plasmoid.configuration.codexEnabled, notify: plasmoid.configuration.codexNotifications },
        { name: "GitHub Copilot", monitor: copilotMonitor, enabled: plasmoid.configuration.copilotEnabled, notify: plasmoid.configuration.copilotNotifications }
    ]

    readonly property int enabledToolCount: {
        var count = 0;
        for (var i = 0; i < allSubscriptionTools.length; i++) {
            if (allSubscriptionTools[i].enabled) count++;
        }
        return count;
    }

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
        for (var i = 0; i < allProviders.length; i++) {
            if (allProviders[i].enabled && allProviders[i].backend.hasApiKey()) {
                allProviders[i].backend.refresh();
            }
        }
    }

    function loadApiKeys() {
        for (var i = 0; i < allProviders.length; i++) {
            if (allProviders[i].enabled) {
                var key = secrets.getKey(allProviders[i].configKey);
                if (key) allProviders[i].backend.setApiKey(key);
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

    function handleToolLimitWarning(toolName, percentUsed) {
        if (!plasmoid.configuration.alertsEnabled) return;
        // Check per-tool notification setting
        var tools = allSubscriptionTools;
        for (var i = 0; i < tools.length; i++) {
            if (tools[i].name === toolName && !tools[i].notify) return;
        }
        if (!canNotify("tool_warning_" + toolName)) return;

        subscriptionNotification.text = i18n("%1: %2% of usage limit reached", toolName, Math.round(percentUsed));
        subscriptionNotification.urgency = percentUsed >= 95 ? Notification.CriticalUrgency : Notification.NormalUrgency;
        subscriptionNotification.sendEvent();
    }

    function handleToolLimitReached(toolName) {
        if (!plasmoid.configuration.alertsEnabled) return;
        var tools = allSubscriptionTools;
        for (var i = 0; i < tools.length; i++) {
            if (tools[i].name === toolName && !tools[i].notify) return;
        }
        if (!canNotify("tool_limit_" + toolName)) return;

        subscriptionNotification.text = i18n("%1: Usage limit reached!", toolName);
        subscriptionNotification.urgency = Notification.CriticalUrgency;
        subscriptionNotification.sendEvent();
    }

    function recordToolUsageSnapshot(monitor) {
        if (!usageDatabase.enabled) return;
        usageDatabase.recordToolSnapshot(
            monitor.toolName,
            monitor.usageCount,
            monitor.usageLimit,
            monitor.periodLabel,
            monitor.planTier,
            monitor.limitReached
        );
    }

    // ── Browser Sync ──

    function performBrowserSync() {
        if (!plasmoid.configuration.browserSyncEnabled) return;

        // Sync Claude Code (claude.ai cookies)
        if (plasmoid.configuration.claudeCodeEnabled && claudeCodeMonitor.installed) {
            var claudeHeader = browserCookies.getCookieHeader("claude.ai");
            if (claudeHeader.length > 0) {
                claudeCodeMonitor.syncFromBrowser(claudeHeader, plasmoid.configuration.browserSyncBrowser);
            }
        }

        // Sync Codex CLI (chatgpt.com cookies)
        if (plasmoid.configuration.codexEnabled && codexCliMonitor.installed) {
            var codexHeader = browserCookies.getCookieHeader("chatgpt.com");
            if (codexHeader.length > 0) {
                codexCliMonitor.syncFromBrowser(codexHeader, plasmoid.configuration.browserSyncBrowser);
            }
        }
    }

    // ── Lifecycle ──

    Component.onCompleted: {
        if (secrets.walletOpen) {
            loadApiKeys();
        }
        // Initial prune of old data
        usageDatabase.pruneOldData();
        // Initial browser sync after a short delay
        if (plasmoid.configuration.browserSyncEnabled) {
            initialSyncTimer.start();
        }
    }

    Timer {
        id: initialSyncTimer
        interval: 5000 // 5 second delay for startup
        repeat: false
        onTriggered: performBrowserSync()
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
            // Update all per-provider timers that use the global default (interval == 0)
            openaiRefreshTimer.interval = effectiveInterval(plasmoid.configuration.openaiRefreshInterval);
            anthropicRefreshTimer.interval = effectiveInterval(plasmoid.configuration.anthropicRefreshInterval);
            googleRefreshTimer.interval = effectiveInterval(plasmoid.configuration.googleRefreshInterval);
            mistralRefreshTimer.interval = effectiveInterval(plasmoid.configuration.mistralRefreshInterval);
            deepseekRefreshTimer.interval = effectiveInterval(plasmoid.configuration.deepseekRefreshInterval);
            groqRefreshTimer.interval = effectiveInterval(plasmoid.configuration.groqRefreshInterval);
            xaiRefreshTimer.interval = effectiveInterval(plasmoid.configuration.xaiRefreshInterval);
        }

        // Subscription tool config changes
        function onClaudeCodeEnabledChanged() {
            claudeCodeMonitor.enabled = plasmoid.configuration.claudeCodeEnabled;
            if (claudeCodeMonitor.enabled) claudeCodeMonitor.checkToolInstalled();
        }
        function onCodexEnabledChanged() {
            codexCliMonitor.enabled = plasmoid.configuration.codexEnabled;
            if (codexCliMonitor.enabled) codexCliMonitor.checkToolInstalled();
        }
        function onCopilotEnabledChanged() {
            copilotMonitor.enabled = plasmoid.configuration.copilotEnabled;
            if (copilotMonitor.enabled) copilotMonitor.checkToolInstalled();
        }
    }
}
