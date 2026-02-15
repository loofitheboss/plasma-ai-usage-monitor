#include "claudecodemonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

ClaudeCodeMonitor::ClaudeCodeMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &ClaudeCodeMonitor::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &ClaudeCodeMonitor::onFileChanged);
}

QString ClaudeCodeMonitor::claudeConfigDir() const
{
    // Claude Code stores config in ~/.claude/ by default
    // Can be overridden with CLAUDE_CONFIG_DIR env var
    QString envDir = QString::fromLocal8Bit(qgetenv("CLAUDE_CONFIG_DIR"));
    if (!envDir.isEmpty()) return envDir;
    return QDir::homePath() + QStringLiteral("/.claude");
}

void ClaudeCodeMonitor::checkToolInstalled()
{
    bool found = false;

    // Check if 'claude' binary exists in PATH
    QString claudePath = QStandardPaths::findExecutable(QStringLiteral("claude"));
    if (!claudePath.isEmpty()) {
        found = true;
    }

    // Also check for ~/.claude/ directory
    QDir configDir(claudeConfigDir());
    if (configDir.exists()) {
        found = true;
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void ClaudeCodeMonitor::setupWatcher()
{
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (dir.exists()) {
        m_watcher->addPath(configDir);

        // Watch key files that change during usage
        QString settingsFile = configDir + QStringLiteral("/settings.json");
        if (QFileInfo::exists(settingsFile)) {
            m_watcher->addPath(settingsFile);
        }

        // Watch projects directory for conversation activity
        QString projectsDir = configDir + QStringLiteral("/projects");
        if (QDir(projectsDir).exists()) {
            m_watcher->addPath(projectsDir);
        }
    }

    // Also watch ~/.claude.json (global state file)
    QString globalState = QDir::homePath() + QStringLiteral("/.claude.json");
    if (QFileInfo::exists(globalState)) {
        m_watcher->addPath(globalState);
    }
}

void ClaudeCodeMonitor::detectActivity()
{
    // Manually check for recent activity by looking at file modification times
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (!dir.exists()) return;

    QDateTime latestMod;

    // Check projects directory for recent changes
    QString projectsDir = configDir + QStringLiteral("/projects");
    QDir pDir(projectsDir);
    if (pDir.exists()) {
        const auto entries = pDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot,
                                                 QDir::Time);
        if (!entries.isEmpty()) {
            latestMod = entries.first().lastModified();
        }
    }

    // Check global state file
    QFileInfo globalState(QDir::homePath() + QStringLiteral("/.claude.json"));
    if (globalState.exists() && globalState.lastModified() > latestMod) {
        latestMod = globalState.lastModified();
    }

    // If we see a new modification since last check, count it as activity
    if (latestMod.isValid() && latestMod > m_lastKnownModification) {
        m_lastKnownModification = latestMod;
        incrementUsage();
    }
}

void ClaudeCodeMonitor::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();
}

void ClaudeCodeMonitor::onFileChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;

    // File changed — likely a conversation turn or config update
    QFileInfo fi(path);
    if (fi.exists() && fi.lastModified() > m_lastKnownModification) {
        m_lastKnownModification = fi.lastModified();
        incrementUsage();
    }

    // Re-add the file to the watcher (QFileSystemWatcher removes files after change)
    if (!m_watcher->files().contains(path) && QFileInfo::exists(path)) {
        m_watcher->addPath(path);
    }
}

QStringList ClaudeCodeMonitor::availablePlans() const
{
    return {
        QStringLiteral("Pro"),
        QStringLiteral("Max 5x"),
        QStringLiteral("Max 20x")
    };
}

int ClaudeCodeMonitor::defaultLimitForPlan(const QString &plan) const
{
    // 5-hour session limits (approximate, vary by message complexity)
    if (plan == QStringLiteral("Pro")) return 45;
    if (plan == QStringLiteral("Max 5x")) return 225;
    if (plan == QStringLiteral("Max 20x")) return 900;
    return 45;
}

int ClaudeCodeMonitor::defaultSecondaryLimitForPlan(const QString &plan) const
{
    // Weekly limits
    if (plan == QStringLiteral("Pro")) return 225;
    if (plan == QStringLiteral("Max 5x")) return 1125;
    if (plan == QStringLiteral("Max 20x")) return 4500;
    return 225;
}

double ClaudeCodeMonitor::subscriptionCost() const
{
    return defaultCostForPlan(planTier());
}

double ClaudeCodeMonitor::defaultCostForPlan(const QString &plan) const
{
    if (plan == QStringLiteral("Pro")) return 20.0;
    if (plan == QStringLiteral("Max 5x")) return 100.0;
    if (plan == QStringLiteral("Max 20x")) return 200.0;
    return 20.0;
}

// --- Browser Sync ---

void ClaudeCodeMonitor::syncFromBrowser(const QString &cookieDbPath, int browserType)
{
    Q_UNUSED(cookieDbPath);
    Q_UNUSED(browserType);

    if (isSyncing()) return;
    setSyncing(true);
    setSyncStatus(QStringLiteral("Syncing..."));

    // We need cookies as a header string. The caller (QML) passes cookieDbPath
    // but we need to read cookies directly. Use BrowserCookieExtractor from QML side
    // which passes the cookie header via a wrapper. For now, fetch account info
    // using the cookie header that will be set by the QML integration layer.

    // This method is called with cookieDbPath containing the cookie header string
    // (passed from QML after BrowserCookieExtractor.getCookieHeader("claude.ai"))
    QString cookieHeader = cookieDbPath; // Reused parameter for cookie header

    if (cookieHeader.isEmpty()) {
        setSyncing(false);
        setSyncStatus(QStringLiteral("No cookies"));
        Q_EMIT syncCompleted(false, QStringLiteral("No session cookies found for claude.ai"));
        return;
    }

    fetchAccountInfo(cookieHeader);
}

void ClaudeCodeMonitor::fetchAccountInfo(const QString &cookieHeader)
{
    QUrl url(QStringLiteral("https://claude.ai/api/auth/current_account"));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Plasma-AI-Monitor/2.3");

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, cookieHeader]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "ClaudeCodeMonitor: Account fetch failed:" << reply->errorString();
            setSyncing(false);
            setSyncStatus(QStringLiteral("Error"));
            Q_EMIT syncCompleted(false, reply->errorString());
            return;
        }

        QByteArray data = reply->readAll();
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isNull() || !doc.isObject()) {
            setSyncing(false);
            setSyncStatus(QStringLiteral("Invalid response"));
            Q_EMIT syncCompleted(false, QStringLiteral("Invalid JSON from Claude API"));
            return;
        }

        QJsonObject root = doc.object();

        // Extract organization UUID
        // The response may have account.uuid or organization.uuid
        QString orgUuid;
        if (root.contains(QStringLiteral("uuid"))) {
            orgUuid = root.value(QStringLiteral("uuid")).toString();
        }
        // Try memberships array
        QJsonArray memberships = root.value(QStringLiteral("memberships")).toArray();
        if (!memberships.isEmpty()) {
            QJsonObject firstMembership = memberships.first().toObject();
            QJsonObject org = firstMembership.value(QStringLiteral("organization")).toObject();
            if (org.contains(QStringLiteral("uuid"))) {
                orgUuid = org.value(QStringLiteral("uuid")).toString();
            }
        }

        if (orgUuid.isEmpty()) {
            // Try alternate path
            orgUuid = root.value(QStringLiteral("account")).toObject()
                          .value(QStringLiteral("uuid")).toString();
        }

        if (orgUuid.isEmpty()) {
            setSyncing(false);
            setSyncStatus(QStringLiteral("No org found"));
            Q_EMIT syncCompleted(false, QStringLiteral("Could not find organization UUID"));
            return;
        }

        m_orgUuid = orgUuid;
        fetchUsageData(orgUuid, cookieHeader);
    });
}

void ClaudeCodeMonitor::fetchUsageData(const QString &orgUuid, const QString &cookieHeader)
{
    QUrl url(QStringLiteral("https://claude.ai/api/organizations/%1/usage").arg(orgUuid));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Plasma-AI-Monitor/2.3");

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply, orgUuid, cookieHeader]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "ClaudeCodeMonitor: Usage fetch failed:" << reply->errorString();
            // Continue to billing data even if usage fails
        } else {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                QJsonObject root = doc.object();

                // Parse session usage
                double sessionPct = root.value(QStringLiteral("current_session_usage_percent")).toDouble(0);
                if (sessionPct > 0 || root.contains(QStringLiteral("current_session_usage_percent"))) {
                    setSessionPercentUsed(sessionPct);
                    setHasSessionInfo(true);
                }

                // Parse weekly usage
                QJsonObject weekly = root.value(QStringLiteral("weekly_usage")).toObject();
                if (!weekly.isEmpty()) {
                    int weeklyUsed = weekly.value(QStringLiteral("used")).toInt(0);
                    int weeklyLimit = weekly.value(QStringLiteral("limit")).toInt(0);
                    QString resetsAt = weekly.value(QStringLiteral("resets_at")).toString();

                    if (weeklyLimit > 0) {
                        setSecondaryUsageCount(weeklyUsed);
                        setSecondaryUsageLimit(weeklyLimit);
                    }
                }

                // Parse daily/5h usage if available
                QJsonObject sessionUsage = root.value(QStringLiteral("session_usage")).toObject();
                if (!sessionUsage.isEmpty()) {
                    int sessionUsed = sessionUsage.value(QStringLiteral("used")).toInt(0);
                    int sessionLimit = sessionUsage.value(QStringLiteral("limit")).toInt(0);
                    if (sessionLimit > 0) {
                        setUsageCount(sessionUsed);
                        setUsageLimit(sessionLimit);
                    }
                }

                // Also try flat structure
                if (root.contains(QStringLiteral("messages_remaining"))) {
                    // Some API versions return remaining count
                    int remaining = root.value(QStringLiteral("messages_remaining")).toInt(-1);
                    int limit = usageLimit();
                    if (remaining >= 0 && limit > 0) {
                        setUsageCount(limit - remaining);
                    }
                }
            }
        }

        // Now fetch billing data
        fetchBillingData(orgUuid, cookieHeader);
    });
}

void ClaudeCodeMonitor::fetchBillingData(const QString &orgUuid, const QString &cookieHeader)
{
    QUrl url(QStringLiteral("https://claude.ai/api/organizations/%1/settings/billing").arg(orgUuid));

    QNetworkRequest request(url);
    request.setRawHeader("Cookie", cookieHeader.toUtf8());
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) Plasma-AI-Monitor/2.3");

    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "ClaudeCodeMonitor: Billing fetch failed:" << reply->errorString();
        } else {
            QByteArray data = reply->readAll();
            QJsonDocument doc = QJsonDocument::fromJson(data);
            if (doc.isObject()) {
                QJsonObject root = doc.object();

                // Parse extra usage
                QJsonObject extraUsage = root.value(QStringLiteral("extra_usage")).toObject();
                if (!extraUsage.isEmpty()) {
                    setHasExtraUsage(true);

                    // spent_cents → dollars/euros
                    double spentCents = extraUsage.value(QStringLiteral("spent_cents")).toDouble(0);
                    setExtraUsageSpent(spentCents / 100.0);

                    double limitCents = extraUsage.value(QStringLiteral("monthly_limit_cents")).toDouble(0);
                    setExtraUsageLimit(limitCents / 100.0);

                    QString resetsAt = extraUsage.value(QStringLiteral("resets_at")).toString();
                    if (!resetsAt.isEmpty()) {
                        setExtraUsageResetDate(QDateTime::fromString(resetsAt, Qt::ISODate));
                    }
                }

                // Try to detect currency from billing info
                QString currency = root.value(QStringLiteral("currency")).toString();
                if (currency == QStringLiteral("eur")) {
                    setCurrencySymbol(QStringLiteral("€"));
                } else if (currency == QStringLiteral("gbp")) {
                    setCurrencySymbol(QStringLiteral("£"));
                } else {
                    setCurrencySymbol(QStringLiteral("$"));
                }

                // Also check top-level spending fields
                if (!root.value(QStringLiteral("spending")).isUndefined()) {
                    QJsonObject spending = root.value(QStringLiteral("spending")).toObject();
                    if (!spending.isEmpty()) {
                        setHasExtraUsage(true);
                        double spent = spending.value(QStringLiteral("amount")).toDouble(0);
                        double limit = spending.value(QStringLiteral("limit")).toDouble(0);
                        if (spent > 0) setExtraUsageSpent(spent);
                        if (limit > 0) setExtraUsageLimit(limit);
                    }
                }
            }
        }

        // Sync complete
        setSyncing(false);
        setLastSyncTime(QDateTime::currentDateTimeUtc());
        setSyncStatus(QStringLiteral("Synced"));
        Q_EMIT syncCompleted(true, QStringLiteral("Claude usage data synced successfully"));
        Q_EMIT usageUpdated();
    });
}
