#ifndef USAGEDATABASE_H
#define USAGEDATABASE_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QVariantList>
#include <QVariantMap>
#include <QSqlDatabase>

/**
 * SQLite database for persisting AI usage history.
 *
 * Stores periodic snapshots of provider usage data and rate limit events.
 * Supports configurable retention and querying by time range for charts.
 */
class UsageDatabase : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(int retentionDays READ retentionDays WRITE setRetentionDays NOTIFY retentionDaysChanged)

public:
    explicit UsageDatabase(QObject *parent = nullptr);
    ~UsageDatabase() override;

    bool isEnabled() const;
    void setEnabled(bool enabled);
    int retentionDays() const;
    void setRetentionDays(int days);

    /**
     * Record a usage snapshot for a provider.
     * Called automatically after each successful refresh.
     */
    Q_INVOKABLE void recordSnapshot(const QString &provider,
                                     qint64 inputTokens,
                                     qint64 outputTokens,
                                     int requestCount,
                                     double cost,
                                     double dailyCost,
                                     double monthlyCost,
                                     int rateLimitRequests,
                                     int rateLimitRequestsRemaining,
                                     int rateLimitTokens,
                                     int rateLimitTokensRemaining);

    /**
     * Record a rate limit event (hitting or approaching limits).
     */
    Q_INVOKABLE void recordRateLimitEvent(const QString &provider,
                                           const QString &eventType,
                                           int percentUsed);

    /**
     * Query usage snapshots for a provider within a time range.
     * Returns a list of QVariantMap with keys: timestamp, inputTokens, outputTokens,
     * requestCount, cost, dailyCost, monthlyCost, rlRequests, rlRequestsRemaining,
     * rlTokens, rlTokensRemaining.
     */
    Q_INVOKABLE QVariantList getSnapshots(const QString &provider,
                                           const QDateTime &from,
                                           const QDateTime &to) const;

    /**
     * Query cost data aggregated by day for a provider.
     * Returns a list of QVariantMap with keys: date, totalCost, maxDailyCost.
     */
    Q_INVOKABLE QVariantList getDailyCosts(const QString &provider,
                                            const QDateTime &from,
                                            const QDateTime &to) const;

    /**
     * Get summary statistics for a provider over a time range.
     * Returns a QVariantMap with keys: totalCost, avgDailyCost, maxDailyCost,
     * totalRequests, peakTokenUsage, snapshotCount.
     */
    Q_INVOKABLE QVariantMap getSummary(const QString &provider,
                                       const QDateTime &from,
                                       const QDateTime &to) const;

    /**
     * Get all providers that have recorded data.
     */
    Q_INVOKABLE QStringList getProviders() const;

    /**
     * Export data as CSV for a provider within a time range.
     */
    Q_INVOKABLE QString exportCsv(const QString &provider,
                                   const QDateTime &from,
                                   const QDateTime &to) const;

    /**
     * Export data as JSON for a provider within a time range.
     */
    Q_INVOKABLE QString exportJson(const QString &provider,
                                    const QDateTime &from,
                                    const QDateTime &to) const;

    /**
     * Remove data older than retentionDays.
     */
    Q_INVOKABLE void pruneOldData();

    /**
     * Get the total database size in bytes.
     */
    Q_INVOKABLE qint64 databaseSize() const;

Q_SIGNALS:
    void enabledChanged();
    void retentionDaysChanged();

private:
    void initDatabase();
    void createTables();

    QSqlDatabase m_db;
    bool m_enabled = true;
    int m_retentionDays = 90;
    bool m_initialized = false;
};

#endif // USAGEDATABASE_H
