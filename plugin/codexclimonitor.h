#ifndef CODEXCLIMONITOR_H
#define CODEXCLIMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QFileSystemWatcher>
#include <QDir>

/**
 * Monitor for OpenAI Codex CLI usage.
 *
 * Codex CLI uses a 5-hour rolling window for usage limits tied to the
 * ChatGPT subscription plan. Limits vary by plan and task type.
 *
 * No public API exists for checking remaining quota. This monitor:
 * 1. Detects if Codex CLI is installed (checks PATH + ~/.codex/)
 * 2. Watches ~/.codex/ for session activity
 * 3. Self-tracks usage counts in the local database
 * 4. Lets users set their plan tier to auto-fill limits
 *
 * Plans and approximate limits (5-hour window):
 * - Plus ($20/mo):    45–225 local messages, 10–60 cloud tasks
 * - Pro ($200/mo):    300–1500 local messages, 50–400 cloud tasks
 * - Business ($30/user/mo): 45–225 local messages
 *
 * Ranges depend on task complexity. We use the lower bound as default.
 */
class CodexCliMonitor : public SubscriptionToolBackend
{
    Q_OBJECT

public:
    explicit CodexCliMonitor(QObject *parent = nullptr);

    // Identity
    QString toolName() const override { return QStringLiteral("Codex CLI"); }
    QString iconName() const override { return QStringLiteral("utilities-terminal"); }
    QString toolColor() const override { return QStringLiteral("#10A37F"); }

    // Period labels
    QString periodLabel() const override { return QStringLiteral("5-hour window"); }

    // Plan management
    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;

    // Tool detection
    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return FiveHour; }

private Q_SLOTS:
    void onDirectoryChanged(const QString &path);

private:
    void setupWatcher();
    QString codexConfigDir() const;

    QFileSystemWatcher *m_watcher;
    QDateTime m_lastKnownModification;
};

#endif // CODEXCLIMONITOR_H
