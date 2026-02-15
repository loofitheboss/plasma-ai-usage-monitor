#include "usagedatabase.h"
#include <QDir>
#include <QStandardPaths>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFileInfo>
#include <QDebug>

static const char *DB_CONNECTION_NAME = "aiusagemonitor_history";

UsageDatabase::UsageDatabase(QObject *parent)
    : QObject(parent)
{
}

UsageDatabase::~UsageDatabase()
{
    if (m_db.isOpen()) {
        m_db.close();
    }
    QSqlDatabase::removeDatabase(QLatin1String(DB_CONNECTION_NAME));
}

bool UsageDatabase::isEnabled() const { return m_enabled; }
void UsageDatabase::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        Q_EMIT enabledChanged();
    }
}

int UsageDatabase::retentionDays() const { return m_retentionDays; }
void UsageDatabase::setRetentionDays(int days)
{
    if (m_retentionDays != days) {
        m_retentionDays = days;
        Q_EMIT retentionDaysChanged();
    }
}

void UsageDatabase::initDatabase()
{
    if (m_initialized)
        return;

    QString dataDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
                      + QStringLiteral("/plasma-ai-usage-monitor");
    QDir().mkpath(dataDir);

    QString dbPath = dataDir + QStringLiteral("/usage_history.db");

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QLatin1String(DB_CONNECTION_NAME));
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "UsageDatabase: Failed to open database:" << m_db.lastError().text();
        return;
    }

    // Enable WAL mode for better concurrent read performance
    QSqlQuery pragma(m_db);
    pragma.exec(QStringLiteral("PRAGMA journal_mode=WAL"));
    pragma.exec(QStringLiteral("PRAGMA synchronous=NORMAL"));

    createTables();
    m_initialized = true;
}

void UsageDatabase::createTables()
{
    QSqlQuery query(m_db);

    // Usage snapshots -- one row per provider per refresh
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS usage_snapshots ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  provider TEXT NOT NULL,"
        "  input_tokens INTEGER DEFAULT 0,"
        "  output_tokens INTEGER DEFAULT 0,"
        "  request_count INTEGER DEFAULT 0,"
        "  cost REAL DEFAULT 0.0,"
        "  daily_cost REAL DEFAULT 0.0,"
        "  monthly_cost REAL DEFAULT 0.0,"
        "  rl_requests INTEGER DEFAULT 0,"
        "  rl_requests_remaining INTEGER DEFAULT 0,"
        "  rl_tokens INTEGER DEFAULT 0,"
        "  rl_tokens_remaining INTEGER DEFAULT 0"
        ")"
    ));

    // Indexes for efficient time-range queries
    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_snapshots_provider_time "
        "ON usage_snapshots(provider, timestamp)"
    ));

    // Rate limit events -- recorded when thresholds are hit
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS rate_limit_events ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  provider TEXT NOT NULL,"
        "  event_type TEXT NOT NULL,"
        "  percent_used INTEGER DEFAULT 0"
        ")"
    ));

    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_ratelimit_provider_time "
        "ON rate_limit_events(provider, timestamp)"
    ));

    // Subscription tool usage snapshots
    query.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS subscription_tool_usage ("
        "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  timestamp DATETIME DEFAULT (datetime('now')),"
        "  tool_name TEXT NOT NULL,"
        "  usage_count INTEGER DEFAULT 0,"
        "  usage_limit INTEGER DEFAULT 0,"
        "  period_type TEXT NOT NULL,"
        "  plan_tier TEXT DEFAULT '',"
        "  limit_reached BOOLEAN DEFAULT 0"
        ")"
    ));

    query.exec(QStringLiteral(
        "CREATE INDEX IF NOT EXISTS idx_tool_usage_name_time "
        "ON subscription_tool_usage(tool_name, timestamp)"
    ));
}

void UsageDatabase::recordSnapshot(const QString &provider,
                                    qint64 inputTokens,
                                    qint64 outputTokens,
                                    int requestCount,
                                    double cost,
                                    double dailyCost,
                                    double monthlyCost,
                                    int rateLimitRequests,
                                    int rateLimitRequestsRemaining,
                                    int rateLimitTokens,
                                    int rateLimitTokensRemaining)
{
    if (!m_enabled)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO usage_snapshots "
        "(provider, input_tokens, output_tokens, request_count, cost, daily_cost, monthly_cost, "
        "rl_requests, rl_requests_remaining, rl_tokens, rl_tokens_remaining) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
    ));
    query.addBindValue(provider);
    query.addBindValue(inputTokens);
    query.addBindValue(outputTokens);
    query.addBindValue(requestCount);
    query.addBindValue(cost);
    query.addBindValue(dailyCost);
    query.addBindValue(monthlyCost);
    query.addBindValue(rateLimitRequests);
    query.addBindValue(rateLimitRequestsRemaining);
    query.addBindValue(rateLimitTokens);
    query.addBindValue(rateLimitTokensRemaining);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record snapshot:" << query.lastError().text();
    }
}

void UsageDatabase::recordRateLimitEvent(const QString &provider,
                                          const QString &eventType,
                                          int percentUsed)
{
    if (!m_enabled)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO rate_limit_events (provider, event_type, percent_used) VALUES (?, ?, ?)"
    ));
    query.addBindValue(provider);
    query.addBindValue(eventType);
    query.addBindValue(percentUsed);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record rate limit event:" << query.lastError().text();
    }
}

void UsageDatabase::recordToolSnapshot(const QString &toolName,
                                        int usageCount,
                                        int usageLimit,
                                        const QString &periodType,
                                        const QString &planTier,
                                        bool limitReached)
{
    if (!m_enabled)
        return;

    initDatabase();
    if (!m_initialized)
        return;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "INSERT INTO subscription_tool_usage "
        "(tool_name, usage_count, usage_limit, period_type, plan_tier, limit_reached) "
        "VALUES (?, ?, ?, ?, ?, ?)"
    ));
    query.addBindValue(toolName);
    query.addBindValue(usageCount);
    query.addBindValue(usageLimit);
    query.addBindValue(periodType);
    query.addBindValue(planTier);
    query.addBindValue(limitReached ? 1 : 0);

    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to record tool snapshot:" << query.lastError().text();
    }
}

QVariantList UsageDatabase::getSnapshots(const QString &provider,
                                          const QDateTime &from,
                                          const QDateTime &to) const
{
    QVariantList results;

    if (!m_initialized)
        return results;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT timestamp, input_tokens, output_tokens, request_count, cost, "
        "daily_cost, monthly_cost, rl_requests, rl_requests_remaining, "
        "rl_tokens, rl_tokens_remaining "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ? "
        "ORDER BY timestamp ASC"
    ));
    query.addBindValue(provider);
    query.addBindValue(from.toUTC().toString(Qt::ISODate));
    query.addBindValue(to.toUTC().toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getSnapshots query failed:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("timestamp")] = query.value(0).toString();
        row[QStringLiteral("inputTokens")] = query.value(1).toLongLong();
        row[QStringLiteral("outputTokens")] = query.value(2).toLongLong();
        row[QStringLiteral("requestCount")] = query.value(3).toInt();
        row[QStringLiteral("cost")] = query.value(4).toDouble();
        row[QStringLiteral("dailyCost")] = query.value(5).toDouble();
        row[QStringLiteral("monthlyCost")] = query.value(6).toDouble();
        row[QStringLiteral("rlRequests")] = query.value(7).toInt();
        row[QStringLiteral("rlRequestsRemaining")] = query.value(8).toInt();
        row[QStringLiteral("rlTokens")] = query.value(9).toInt();
        row[QStringLiteral("rlTokensRemaining")] = query.value(10).toInt();
        results.append(row);
    }

    return results;
}

QVariantList UsageDatabase::getDailyCosts(const QString &provider,
                                           const QDateTime &from,
                                           const QDateTime &to) const
{
    QVariantList results;

    if (!m_initialized)
        return results;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT date(timestamp) as day, MAX(cost) as total_cost, MAX(daily_cost) as max_daily "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ? "
        "GROUP BY day ORDER BY day ASC"
    ));
    query.addBindValue(provider);
    query.addBindValue(from.toUTC().toString(Qt::ISODate));
    query.addBindValue(to.toUTC().toString(Qt::ISODate));

    if (!query.exec()) {
        qWarning() << "UsageDatabase: getDailyCosts query failed:" << query.lastError().text();
        return results;
    }

    while (query.next()) {
        QVariantMap row;
        row[QStringLiteral("date")] = query.value(0).toString();
        row[QStringLiteral("totalCost")] = query.value(1).toDouble();
        row[QStringLiteral("maxDailyCost")] = query.value(2).toDouble();
        results.append(row);
    }

    return results;
}

QVariantMap UsageDatabase::getSummary(const QString &provider,
                                      const QDateTime &from,
                                      const QDateTime &to) const
{
    QVariantMap result;

    if (!m_initialized)
        return result;

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "SELECT MAX(cost) as total_cost, "
        "AVG(daily_cost) as avg_daily, MAX(daily_cost) as max_daily, "
        "MAX(request_count) as total_requests, "
        "MAX(input_tokens + output_tokens) as peak_tokens, "
        "COUNT(*) as snapshot_count "
        "FROM usage_snapshots "
        "WHERE provider = ? AND timestamp >= ? AND timestamp <= ?"
    ));
    query.addBindValue(provider);
    query.addBindValue(from.toUTC().toString(Qt::ISODate));
    query.addBindValue(to.toUTC().toString(Qt::ISODate));

    if (!query.exec() || !query.next()) {
        qWarning() << "UsageDatabase: getSummary query failed:" << query.lastError().text();
        return result;
    }

    result[QStringLiteral("totalCost")] = query.value(0).toDouble();
    result[QStringLiteral("avgDailyCost")] = query.value(1).toDouble();
    result[QStringLiteral("maxDailyCost")] = query.value(2).toDouble();
    result[QStringLiteral("totalRequests")] = query.value(3).toInt();
    result[QStringLiteral("peakTokenUsage")] = query.value(4).toLongLong();
    result[QStringLiteral("snapshotCount")] = query.value(5).toInt();

    return result;
}

QStringList UsageDatabase::getProviders() const
{
    QStringList providers;

    if (!m_initialized)
        return providers;

    QSqlQuery query(m_db);
    query.exec(QStringLiteral(
        "SELECT DISTINCT provider FROM usage_snapshots ORDER BY provider"
    ));

    while (query.next()) {
        providers.append(query.value(0).toString());
    }

    return providers;
}

QString UsageDatabase::exportCsv(const QString &provider,
                                  const QDateTime &from,
                                  const QDateTime &to) const
{
    QString csv;
    csv += QStringLiteral("timestamp,provider,input_tokens,output_tokens,request_count,"
                          "cost,daily_cost,monthly_cost,rl_requests,rl_requests_remaining,"
                          "rl_tokens,rl_tokens_remaining\n");

    QVariantList snapshots = getSnapshots(provider, from, to);
    for (const QVariant &snap : snapshots) {
        QVariantMap row = snap.toMap();
        // Qt's multi-arg .arg() supports at most 9 QString arguments,
        // so we split into two chained calls.
        csv += QStringLiteral("%1,%2,%3,%4,%5,%6,%7,%8,%9,")
                   .arg(row[QStringLiteral("timestamp")].toString(),
                        provider,
                        QString::number(row[QStringLiteral("inputTokens")].toLongLong()),
                        QString::number(row[QStringLiteral("outputTokens")].toLongLong()),
                        QString::number(row[QStringLiteral("requestCount")].toInt()),
                        QString::number(row[QStringLiteral("cost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("dailyCost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("monthlyCost")].toDouble(), 'f', 6),
                        QString::number(row[QStringLiteral("rlRequests")].toInt()));
        csv += QStringLiteral("%1,%2,%3\n")
                   .arg(QString::number(row[QStringLiteral("rlRequestsRemaining")].toInt()),
                        QString::number(row[QStringLiteral("rlTokens")].toInt()),
                        QString::number(row[QStringLiteral("rlTokensRemaining")].toInt()));
    }

    return csv;
}

QString UsageDatabase::exportJson(const QString &provider,
                                   const QDateTime &from,
                                   const QDateTime &to) const
{
    QVariantList snapshots = getSnapshots(provider, from, to);

    QJsonArray arr;
    for (const QVariant &snap : snapshots) {
        arr.append(QJsonObject::fromVariantMap(snap.toMap()));
    }

    QJsonObject root;
    root[QStringLiteral("provider")] = provider;
    root[QStringLiteral("from")] = from.toString(Qt::ISODate);
    root[QStringLiteral("to")] = to.toString(Qt::ISODate);
    root[QStringLiteral("snapshots")] = arr;

    return QString::fromUtf8(QJsonDocument(root).toJson(QJsonDocument::Indented));
}

void UsageDatabase::pruneOldData()
{
    if (!m_initialized)
        return;

    QDateTime cutoff = QDateTime::currentDateTimeUtc().addDays(-m_retentionDays);

    QSqlQuery query(m_db);
    query.prepare(QStringLiteral(
        "DELETE FROM usage_snapshots WHERE timestamp < ?"
    ));
    query.addBindValue(cutoff.toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune snapshots:" << query.lastError().text();
    }

    query.prepare(QStringLiteral(
        "DELETE FROM rate_limit_events WHERE timestamp < ?"
    ));
    query.addBindValue(cutoff.toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune events:" << query.lastError().text();
    }

    query.prepare(QStringLiteral(
        "DELETE FROM subscription_tool_usage WHERE timestamp < ?"
    ));
    query.addBindValue(cutoff.toString(Qt::ISODate));
    if (!query.exec()) {
        qWarning() << "UsageDatabase: Failed to prune tool usage:" << query.lastError().text();
    }

    // Reclaim space
    QSqlQuery vacuum(m_db);
    vacuum.exec(QStringLiteral("PRAGMA incremental_vacuum"));
}

qint64 UsageDatabase::databaseSize() const
{
    if (!m_initialized)
        return 0;

    QFileInfo fi(m_db.databaseName());
    return fi.size();
}
