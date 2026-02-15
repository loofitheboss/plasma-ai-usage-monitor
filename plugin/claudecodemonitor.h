#ifndef CLAUDECODEMONITOR_H
#define CLAUDECODEMONITOR_H

#include "subscriptiontoolbackend.h"
#include <QFileSystemWatcher>
#include <QDir>

/**
 * Monitor for Claude Code CLI usage.
 *
 * Claude Code (Anthropic) uses rolling time windows:
 * - Primary: 5-hour session window
 * - Secondary: Weekly rolling window (separate Opus/non-Opus limits)
 *
 * No public API exists for checking remaining quota. This monitor:
 * 1. Detects if Claude Code CLI is installed (checks PATH + ~/.claude/)
 * 2. Watches ~/.claude/ for file changes indicating activity
 * 3. Self-tracks usage counts in the local database
 * 4. Lets users set their plan tier (Pro/Max5x/Max20x) to auto-fill limits
 *
 * Plans and approximate limits (messages vary by complexity):
 * - Pro ($20/mo):    ~45 messages/5h session, ~225/week
 * - Max 5x ($100/mo): ~225 messages/5h session, ~1125/week
 * - Max 20x ($200/mo): ~900 messages/5h session, ~4500/week
 */
class ClaudeCodeMonitor : public SubscriptionToolBackend
{
    Q_OBJECT

public:
    explicit ClaudeCodeMonitor(QObject *parent = nullptr);

    // Identity
    QString toolName() const override { return QStringLiteral("Claude Code"); }
    QString iconName() const override { return QStringLiteral("utilities-terminal"); }
    QString toolColor() const override { return QStringLiteral("#D4A574"); }

    // Period labels
    QString periodLabel() const override { return QStringLiteral("5-hour session"); }
    QString secondaryPeriodLabel() const override { return QStringLiteral("Weekly"); }
    bool hasSecondaryLimit() const override { return true; }

    // Plan management
    Q_INVOKABLE QStringList availablePlans() const override;
    Q_INVOKABLE int defaultLimitForPlan(const QString &plan) const override;
    Q_INVOKABLE int defaultSecondaryLimitForPlan(const QString &plan) const override;

    // Tool detection
    Q_INVOKABLE void checkToolInstalled() override;
    Q_INVOKABLE void detectActivity() override;

protected:
    UsagePeriod primaryPeriodType() const override { return FiveHour; }
    UsagePeriod secondaryPeriodType() const override { return Weekly; }

private Q_SLOTS:
    void onDirectoryChanged(const QString &path);
    void onFileChanged(const QString &path);

private:
    void setupWatcher();
    QString claudeConfigDir() const;

    QFileSystemWatcher *m_watcher;
    QDateTime m_lastKnownModification;
};

#endif // CLAUDECODEMONITOR_H
