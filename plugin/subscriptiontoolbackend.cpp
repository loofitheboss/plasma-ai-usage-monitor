#include "subscriptiontoolbackend.h"
#include <QDate>
#include <QDebug>
#include <QTimeZone>

SubscriptionToolBackend::SubscriptionToolBackend(QObject *parent)
    : QObject(parent)
    , m_resetCheckTimer(new QTimer(this))
{
    // Check for period resets every 60 seconds
    m_resetCheckTimer->setInterval(60 * 1000);
    connect(m_resetCheckTimer, &QTimer::timeout, this, &SubscriptionToolBackend::checkAndResetPeriod);
}

SubscriptionToolBackend::~SubscriptionToolBackend() = default;

// --- State ---

bool SubscriptionToolBackend::isEnabled() const { return m_enabled; }
void SubscriptionToolBackend::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        if (enabled) {
            checkToolInstalled();
            if (m_periodStart.isNull()) {
                m_periodStart = QDateTime::currentDateTimeUtc();
                m_secondaryPeriodStart = QDateTime::currentDateTimeUtc();
            }
            m_resetCheckTimer->start();
        } else {
            m_resetCheckTimer->stop();
        }
        Q_EMIT enabledChanged();
    }
}

bool SubscriptionToolBackend::isInstalled() const { return m_installed; }
void SubscriptionToolBackend::setInstalled(bool installed)
{
    if (m_installed != installed) {
        m_installed = installed;
        Q_EMIT installedChanged();
    }
}

QString SubscriptionToolBackend::planTier() const { return m_planTier; }
void SubscriptionToolBackend::setPlanTier(const QString &tier)
{
    if (m_planTier != tier) {
        m_planTier = tier;
        Q_EMIT planTierChanged();
    }
}

// --- Usage ---

int SubscriptionToolBackend::usageCount() const { return m_usageCount; }
void SubscriptionToolBackend::setUsageCount(int count)
{
    m_usageCount = count;
}

int SubscriptionToolBackend::usageLimit() const { return m_usageLimit; }
void SubscriptionToolBackend::setUsageLimit(int limit)
{
    if (m_usageLimit != limit) {
        m_usageLimit = limit;
        Q_EMIT usageLimitChanged();
    }
}

double SubscriptionToolBackend::percentUsed() const
{
    if (m_usageLimit <= 0) return 0.0;
    return (static_cast<double>(m_usageCount) / m_usageLimit) * 100.0;
}

bool SubscriptionToolBackend::isLimitReached() const
{
    return m_usageLimit > 0 && m_usageCount >= m_usageLimit;
}

// --- Secondary Window ---

int SubscriptionToolBackend::secondaryUsageCount() const { return m_secondaryUsageCount; }
void SubscriptionToolBackend::setSecondaryUsageCount(int count)
{
    m_secondaryUsageCount = count;
}

int SubscriptionToolBackend::secondaryUsageLimit() const { return m_secondaryUsageLimit; }
void SubscriptionToolBackend::setSecondaryUsageLimit(int limit)
{
    if (m_secondaryUsageLimit != limit) {
        m_secondaryUsageLimit = limit;
        Q_EMIT usageLimitChanged();
    }
}

double SubscriptionToolBackend::secondaryPercentUsed() const
{
    if (m_secondaryUsageLimit <= 0) return 0.0;
    return (static_cast<double>(m_secondaryUsageCount) / m_secondaryUsageLimit) * 100.0;
}

bool SubscriptionToolBackend::isSecondaryLimitReached() const
{
    return m_secondaryUsageLimit > 0 && m_secondaryUsageCount >= m_secondaryUsageLimit;
}

QString SubscriptionToolBackend::secondaryPeriodLabel() const { return QString(); }
bool SubscriptionToolBackend::hasSecondaryLimit() const { return false; }
SubscriptionToolBackend::UsagePeriod SubscriptionToolBackend::secondaryPeriodType() const { return Weekly; }
int SubscriptionToolBackend::defaultSecondaryLimitForPlan(const QString &) const { return 0; }

// --- Time ---

QDateTime SubscriptionToolBackend::periodStart() const { return m_periodStart; }
void SubscriptionToolBackend::setPeriodStart(const QDateTime &start) { m_periodStart = start; }

QDateTime SubscriptionToolBackend::periodEnd() const
{
    return calculatePeriodEnd(primaryPeriodType(), m_periodStart);
}

int SubscriptionToolBackend::secondsUntilReset() const
{
    QDateTime end = periodEnd();
    if (!end.isValid()) return 0;
    qint64 secs = QDateTime::currentDateTimeUtc().secsTo(end);
    return secs > 0 ? static_cast<int>(secs) : 0;
}

QString SubscriptionToolBackend::timeUntilReset() const
{
    int secs = secondsUntilReset();
    if (secs <= 0) return QStringLiteral("now");

    int hours = secs / 3600;
    int mins = (secs % 3600) / 60;

    if (hours > 24) {
        int days = hours / 24;
        return QStringLiteral("%1d %2h").arg(days).arg(hours % 24);
    }
    if (hours > 0) {
        return QStringLiteral("%1h %2m").arg(hours).arg(mins);
    }
    return QStringLiteral("%1m").arg(mins);
}

QDateTime SubscriptionToolBackend::lastActivity() const { return m_lastActivity; }
void SubscriptionToolBackend::setLastActivity(const QDateTime &time) { m_lastActivity = time; }

// --- Actions ---

void SubscriptionToolBackend::incrementUsage()
{
    checkAndResetPeriod();

    m_usageCount++;
    m_secondaryUsageCount++;
    m_lastActivity = QDateTime::currentDateTimeUtc();

    checkLimitWarnings();
    Q_EMIT usageUpdated();
    Q_EMIT activityDetected(toolName());
}

void SubscriptionToolBackend::resetUsage()
{
    m_usageCount = 0;
    m_periodStart = QDateTime::currentDateTimeUtc();
    Q_EMIT usageUpdated();
}

// --- Period Management ---

QDateTime SubscriptionToolBackend::calculatePeriodEnd(UsagePeriod period, const QDateTime &start) const
{
    if (!start.isValid()) return QDateTime();

    switch (period) {
    case FiveHour:
        return start.addSecs(5 * 3600);
    case Daily:
        return start.addDays(1);
    case Weekly:
        return start.addDays(7);
    case Monthly: {
        // Reset on 1st of next month at 00:00 UTC
        QDate d = start.date();
        QDate firstOfNext = d.addMonths(1);
        firstOfNext = QDate(firstOfNext.year(), firstOfNext.month(), 1);
        return QDateTime(firstOfNext, QTime(0, 0), QTimeZone::utc());
    }
    }
    return QDateTime();
}

void SubscriptionToolBackend::checkAndResetPeriod()
{
    QDateTime now = QDateTime::currentDateTimeUtc();

    // Check primary period
    QDateTime end = calculatePeriodEnd(primaryPeriodType(), m_periodStart);
    if (end.isValid() && now >= end) {
        m_usageCount = 0;
        m_periodStart = now;
        Q_EMIT usageUpdated();
    }

    // Check secondary period
    if (hasSecondaryLimit()) {
        QDateTime secEnd = calculatePeriodEnd(secondaryPeriodType(), m_secondaryPeriodStart);
        if (secEnd.isValid() && now >= secEnd) {
            m_secondaryUsageCount = 0;
            m_secondaryPeriodStart = now;
            Q_EMIT usageUpdated();
        }
    }
}

// --- Warning Checks ---

void SubscriptionToolBackend::checkLimitWarnings()
{
    if (m_usageLimit <= 0) return;

    double pct = percentUsed();

    if (m_usageCount >= m_usageLimit) {
        Q_EMIT limitReached(toolName());
    } else if (pct >= 80.0) {
        Q_EMIT limitWarning(toolName(), static_cast<int>(pct));
    }

    // Check secondary limit too
    if (hasSecondaryLimit() && m_secondaryUsageLimit > 0) {
        if (m_secondaryUsageCount >= m_secondaryUsageLimit) {
            Q_EMIT limitReached(toolName());
        }
    }
}
