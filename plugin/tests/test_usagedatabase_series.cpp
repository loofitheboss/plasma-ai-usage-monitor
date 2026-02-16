#include <QtTest>

#include <QStandardPaths>
#include <QSqlDatabase>
#include <QSqlError>
#include <QSqlQuery>
#include <QTemporaryDir>
#include <QUuid>
#include <cmath>

#include "usagedatabase.h"

namespace {
QString dbFilePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/plasma-ai-usage-monitor/usage_history.db");
}

bool updateProviderSnapshotTimestamp(const QString &provider, double cost, const QString &timestamp)
{
    const QString connName = QStringLiteral("usage_test_conn_%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
        db.setDatabaseName(dbFilePath());
        if (!db.open()) {
            qWarning() << "Failed to open DB for timestamp update:" << db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "UPDATE usage_snapshots SET timestamp = ? "
                "WHERE provider = ? AND ABS(cost - ?) < 0.00001"
            ));
            query.addBindValue(timestamp);
            query.addBindValue(provider);
            query.addBindValue(cost);

            ok = query.exec() && query.numRowsAffected() > 0;
            if (!ok) {
                qWarning() << "Provider timestamp update failed:" << query.lastError().text();
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connName);
    return ok;
}

bool updateToolSnapshotTimestamp(const QString &tool, int usageCount, const QString &timestamp)
{
    const QString connName = QStringLiteral("tool_test_conn_%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    bool ok = false;
    {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), connName);
        db.setDatabaseName(dbFilePath());
        if (!db.open()) {
            qWarning() << "Failed to open DB for tool timestamp update:" << db.lastError().text();
        } else {
            QSqlQuery query(db);
            query.prepare(QStringLiteral(
                "UPDATE subscription_tool_usage SET timestamp = ? "
                "WHERE tool_name = ? AND usage_count = ?"
            ));
            query.addBindValue(timestamp);
            query.addBindValue(tool);
            query.addBindValue(usageCount);

            ok = query.exec() && query.numRowsAffected() > 0;
            if (!ok) {
                qWarning() << "Tool timestamp update failed:" << query.lastError().text();
            }
            db.close();
        }
    }
    QSqlDatabase::removeDatabase(connName);
    return ok;
}

double pointValue(const QVariantList &points, int index)
{
    return points.at(index).toMap().value(QStringLiteral("value")).toDouble();
}
} // namespace

class UsageDatabaseSeriesTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void providerSeriesMetrics();
    void toolSeriesMetrics();
};

void UsageDatabaseSeriesTest::providerSeriesMetrics()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    qputenv("XDG_DATA_HOME", tmp.path().toUtf8());

    UsageDatabase db;
    db.init();

    db.recordSnapshot(QStringLiteral("OpenAI"), 100, 50, 10, 1.0, 1.0, 10.0, 100, 90, 1000, 950);
    db.recordSnapshot(QStringLiteral("OpenAI"), 250, 100, 20, 2.0, 2.0, 20.0, 100, 70, 1000, 800);
    db.recordSnapshot(QStringLiteral("OpenAI"), 400, 200, 40, 4.0, 4.0, 40.0, 100, 30, 1000, 500);

    QVERIFY(updateProviderSnapshotTimestamp(QStringLiteral("OpenAI"), 1.0, QStringLiteral("2026-01-01 00:00:00")));
    QVERIFY(updateProviderSnapshotTimestamp(QStringLiteral("OpenAI"), 2.0, QStringLiteral("2026-01-01 01:00:00")));
    QVERIFY(updateProviderSnapshotTimestamp(QStringLiteral("OpenAI"), 4.0, QStringLiteral("2026-01-01 02:00:00")));

    const QDateTime from = QDateTime::fromString(QStringLiteral("2026-01-01T00:00:00Z"), Qt::ISODate);
    const QDateTime to = QDateTime::fromString(QStringLiteral("2026-01-01T03:00:00Z"), Qt::ISODate);

    const QVariantList tokensSeries = db.getProviderSeries({QStringLiteral("OpenAI")}, from, to,
                                                           QStringLiteral("tokens"), 60);
    QCOMPARE(tokensSeries.size(), 1);

    const QVariantMap tokenSeries = tokensSeries.first().toMap();
    QVERIFY(tokenSeries.contains(QStringLiteral("name")));
    QVERIFY(tokenSeries.contains(QStringLiteral("points")));
    QVERIFY(tokenSeries.contains(QStringLiteral("latestValue")));
    QVERIFY(tokenSeries.contains(QStringLiteral("deltaPercent")));
    QVERIFY(tokenSeries.contains(QStringLiteral("sampleCount")));

    QCOMPARE(tokenSeries.value(QStringLiteral("name")).toString(), QStringLiteral("OpenAI"));
    QCOMPARE(tokenSeries.value(QStringLiteral("sampleCount")).toInt(), 3);

    const QVariantList tokenPoints = tokenSeries.value(QStringLiteral("points")).toList();
    QCOMPARE(tokenPoints.size(), 3);
    QVERIFY(std::abs(pointValue(tokenPoints, 0) - 150.0) < 0.01);
    QVERIFY(std::abs(pointValue(tokenPoints, 1) - 350.0) < 0.01);
    QVERIFY(std::abs(pointValue(tokenPoints, 2) - 600.0) < 0.01);
    QVERIFY(std::abs(tokenSeries.value(QStringLiteral("latestValue")).toDouble() - 600.0) < 0.01);
    QVERIFY(std::abs(tokenSeries.value(QStringLiteral("deltaPercent")).toDouble() - 300.0) < 0.01);

    const QVariantList rateSeries = db.getProviderSeries({QStringLiteral("OpenAI")}, from, to,
                                                         QStringLiteral("rateLimitUsed"), 60);
    QCOMPARE(rateSeries.size(), 1);
    const QVariantList ratePoints = rateSeries.first().toMap().value(QStringLiteral("points")).toList();
    QCOMPARE(ratePoints.size(), 3);
    QVERIFY(std::abs(pointValue(ratePoints, 0) - 10.0) < 0.01);
    QVERIFY(std::abs(pointValue(ratePoints, 1) - 30.0) < 0.01);
    QVERIFY(std::abs(pointValue(ratePoints, 2) - 70.0) < 0.01);

    const QVariantList bucketedCostSeries = db.getProviderSeries({QStringLiteral("OpenAI")}, from, to,
                                                                 QStringLiteral("cost"), 120);
    QCOMPARE(bucketedCostSeries.size(), 1);
    const QVariantList bucketedCostPoints = bucketedCostSeries.first().toMap().value(QStringLiteral("points")).toList();
    QCOMPARE(bucketedCostPoints.size(), 2);
    QVERIFY(std::abs(pointValue(bucketedCostPoints, 0) - 1.5) < 0.01);
    QVERIFY(std::abs(pointValue(bucketedCostPoints, 1) - 4.0) < 0.01);
}

void UsageDatabaseSeriesTest::toolSeriesMetrics()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    qputenv("XDG_DATA_HOME", tmp.path().toUtf8());

    UsageDatabase db;
    db.init();

    db.recordToolSnapshot(QStringLiteral("Codex CLI"), 10, 100, QStringLiteral("5-hour"), QStringLiteral("Pro"), false);
    db.recordToolSnapshot(QStringLiteral("Codex CLI"), 30, 100, QStringLiteral("5-hour"), QStringLiteral("Pro"), false);
    db.recordToolSnapshot(QStringLiteral("Codex CLI"), 80, 100, QStringLiteral("5-hour"), QStringLiteral("Pro"), false);

    QVERIFY(updateToolSnapshotTimestamp(QStringLiteral("Codex CLI"), 10, QStringLiteral("2026-01-01 00:00:00")));
    QVERIFY(updateToolSnapshotTimestamp(QStringLiteral("Codex CLI"), 30, QStringLiteral("2026-01-01 01:00:00")));
    QVERIFY(updateToolSnapshotTimestamp(QStringLiteral("Codex CLI"), 80, QStringLiteral("2026-01-01 02:00:00")));

    const QDateTime from = QDateTime::fromString(QStringLiteral("2026-01-01T00:00:00Z"), Qt::ISODate);
    const QDateTime to = QDateTime::fromString(QStringLiteral("2026-01-01T03:00:00Z"), Qt::ISODate);

    const QVariantList percentSeries = db.getToolSeries({QStringLiteral("Codex CLI")}, from, to,
                                                        QStringLiteral("percentUsed"), 60);
    QCOMPARE(percentSeries.size(), 1);
    const QVariantMap percentMap = percentSeries.first().toMap();
    QCOMPARE(percentMap.value(QStringLiteral("sampleCount")).toInt(), 3);

    const QVariantList percentPoints = percentMap.value(QStringLiteral("points")).toList();
    QCOMPARE(percentPoints.size(), 3);
    QVERIFY(std::abs(pointValue(percentPoints, 0) - 10.0) < 0.01);
    QVERIFY(std::abs(pointValue(percentPoints, 1) - 30.0) < 0.01);
    QVERIFY(std::abs(pointValue(percentPoints, 2) - 80.0) < 0.01);

    const QVariantList remainingSeries = db.getToolSeries({QStringLiteral("Codex CLI")}, from, to,
                                                          QStringLiteral("remaining"), 60);
    QCOMPARE(remainingSeries.size(), 1);
    const QVariantList remainingPoints = remainingSeries.first().toMap().value(QStringLiteral("points")).toList();
    QCOMPARE(remainingPoints.size(), 3);
    QVERIFY(std::abs(pointValue(remainingPoints, 0) - 90.0) < 0.01);
    QVERIFY(std::abs(pointValue(remainingPoints, 1) - 70.0) < 0.01);
    QVERIFY(std::abs(pointValue(remainingPoints, 2) - 20.0) < 0.01);

    const QVariantList bucketedUsageSeries = db.getToolSeries({QStringLiteral("Codex CLI")}, from, to,
                                                              QStringLiteral("usageCount"), 120);
    QCOMPARE(bucketedUsageSeries.size(), 1);
    const QVariantList bucketedUsagePoints = bucketedUsageSeries.first().toMap().value(QStringLiteral("points")).toList();
    QCOMPARE(bucketedUsagePoints.size(), 2);
    QVERIFY(std::abs(pointValue(bucketedUsagePoints, 0) - 20.0) < 0.01);
    QVERIFY(std::abs(pointValue(bucketedUsagePoints, 1) - 80.0) < 0.01);
}

QTEST_MAIN(UsageDatabaseSeriesTest)
#include "test_usagedatabase_series.moc"
