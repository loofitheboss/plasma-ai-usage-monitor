#ifndef SUBSCRIPTIONTOOLBACKEND_H
#define SUBSCRIPTIONTOOLBACKEND_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QTimer>

/**
 * Abstract base class for subscription-based AI coding tool monitors.
 *
 * Unlike ProviderBackend (which tracks API billing/tokens), this class
 * tracks usage counts against fixed subscription limits with rolling
 * time windows (5-hour, daily, weekly, monthly).
 *
 * Subclasses implement tool-specific detection and monitoring logic
 * for tools like Claude Code, OpenAI Codex CLI, and GitHub Copilot.
 *
 * Usage is self-tracked locally in the SQLite database since none of
 * these tools expose public APIs for individual quota checking.
 */
class SubscriptionToolBackend : public QObject
{
    Q_OBJECT

    // Identity
    Q_PROPERTY(QString toolName READ toolName CONSTANT)
    Q_PROPERTY(QString iconName READ iconName CONSTANT)
    Q_PROPERTY(QString toolColor READ toolColor CONSTANT)

    // State
    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool installed READ isInstalled NOTIFY installedChanged)
    Q_PROPERTY(QString planTier READ planTier WRITE setPlanTier NOTIFY planTierChanged)

    // Usage tracking
    Q_PROPERTY(int usageCount READ usageCount NOTIFY usageUpdated)
    Q_PROPERTY(int usageLimit READ usageLimit WRITE setUsageLimit NOTIFY usageLimitChanged)
    Q_PROPERTY(double percentUsed READ percentUsed NOTIFY usageUpdated)
    Q_PROPERTY(bool limitReached READ isLimitReached NOTIFY usageUpdated)
    Q_PROPERTY(QString periodLabel READ periodLabel CONSTANT)

    // Secondary usage window (e.g., weekly limit alongside 5-hour session)
    Q_PROPERTY(int secondaryUsageCount READ secondaryUsageCount NOTIFY usageUpdated)
    Q_PROPERTY(int secondaryUsageLimit READ secondaryUsageLimit WRITE setSecondaryUsageLimit NOTIFY usageLimitChanged)
    Q_PROPERTY(double secondaryPercentUsed READ secondaryPercentUsed NOTIFY usageUpdated)
    Q_PROPERTY(bool secondaryLimitReached READ isSecondaryLimitReached NOTIFY usageUpdated)
    Q_PROPERTY(QString secondaryPeriodLabel READ secondaryPeriodLabel CONSTANT)
    Q_PROPERTY(bool hasSecondaryLimit READ hasSecondaryLimit CONSTANT)

    // Time tracking
    Q_PROPERTY(QDateTime periodStart READ periodStart NOTIFY usageUpdated)
    Q_PROPERTY(QDateTime periodEnd READ periodEnd NOTIFY usageUpdated)
    Q_PROPERTY(int secondsUntilReset READ secondsUntilReset NOTIFY usageUpdated)
    Q_PROPERTY(QString timeUntilReset READ timeUntilReset NOTIFY usageUpdated)
    Q_PROPERTY(QDateTime lastActivity READ lastActivity NOTIFY usageUpdated)

public:
    enum UsagePeriod {
        FiveHour,   // 5-hour rolling window (Claude Code, Codex)
        Daily,      // 24-hour from midnight
        Weekly,     // 7-day rolling window
        Monthly     // Calendar month (resets 1st)
    };
    Q_ENUM(UsagePeriod)

    explicit SubscriptionToolBackend(QObject *parent = nullptr);
    ~SubscriptionToolBackend() override;

    // Identity (pure virtual — subclasses must implement)
    virtual QString toolName() const = 0;
    virtual QString iconName() const = 0;
    virtual QString toolColor() const = 0;

    // State
    bool isEnabled() const;
    void setEnabled(bool enabled);
    bool isInstalled() const;
    QString planTier() const;
    void setPlanTier(const QString &tier);

    // Usage
    int usageCount() const;
    int usageLimit() const;
    void setUsageLimit(int limit);
    double percentUsed() const;
    bool isLimitReached() const;
    virtual QString periodLabel() const = 0;

    // Secondary window
    int secondaryUsageCount() const;
    int secondaryUsageLimit() const;
    void setSecondaryUsageLimit(int limit);
    double secondaryPercentUsed() const;
    bool isSecondaryLimitReached() const;
    virtual QString secondaryPeriodLabel() const;
    virtual bool hasSecondaryLimit() const;

    // Time
    QDateTime periodStart() const;
    QDateTime periodEnd() const;
    int secondsUntilReset() const;
    QString timeUntilReset() const;
    QDateTime lastActivity() const;

    // Actions
    Q_INVOKABLE void incrementUsage();
    Q_INVOKABLE void resetUsage();
    Q_INVOKABLE virtual void checkToolInstalled() = 0;
    Q_INVOKABLE virtual void detectActivity() = 0;

    // Plan presets (subclasses populate these)
    Q_INVOKABLE virtual QStringList availablePlans() const = 0;
    Q_INVOKABLE virtual int defaultLimitForPlan(const QString &plan) const = 0;
    Q_INVOKABLE virtual int defaultSecondaryLimitForPlan(const QString &plan) const;

Q_SIGNALS:
    void enabledChanged();
    void installedChanged();
    void planTierChanged();
    void usageUpdated();
    void usageLimitChanged();
    void limitWarning(const QString &tool, int percentUsed);
    void limitReached(const QString &tool);
    void activityDetected(const QString &tool);

protected:
    void setInstalled(bool installed);
    void setUsageCount(int count);
    void setSecondaryUsageCount(int count);
    void setPeriodStart(const QDateTime &start);
    void setLastActivity(const QDateTime &time);

    // Period management
    virtual UsagePeriod primaryPeriodType() const = 0;
    virtual UsagePeriod secondaryPeriodType() const;
    void checkAndResetPeriod();
    QDateTime calculatePeriodEnd(UsagePeriod period, const QDateTime &start) const;

private:
    void checkLimitWarnings();

    bool m_enabled = false;
    bool m_installed = false;
    QString m_planTier;

    int m_usageCount = 0;
    int m_usageLimit = 0;
    int m_secondaryUsageCount = 0;
    int m_secondaryUsageLimit = 0;

    QDateTime m_periodStart;
    QDateTime m_secondaryPeriodStart;
    QDateTime m_lastActivity;

    QTimer *m_resetCheckTimer;
};

#endif // SUBSCRIPTIONTOOLBACKEND_H
