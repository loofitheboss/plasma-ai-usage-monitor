#include <QtTest>

#include <QTemporaryDir>

#include "usagedatabase.h"

class HistoryMappingRegressionTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void displayNameVsDbNameQueries();
};

void HistoryMappingRegressionTest::displayNameVsDbNameQueries()
{
    QTemporaryDir tmp;
    QVERIFY(tmp.isValid());
    qputenv("XDG_DATA_HOME", tmp.path().toUtf8());

    UsageDatabase db;
    db.init();

    db.recordSnapshot(QStringLiteral("Google"), 100, 50, 10, 1.0, 1.0, 10.0, 0, 0, 0, 0);
    db.recordSnapshot(QStringLiteral("xAI"), 120, 80, 15, 2.0, 2.0, 20.0, 0, 0, 0, 0);

    const QDateTime from = QDateTime::currentDateTimeUtc().addSecs(-3600);
    const QDateTime to = QDateTime::currentDateTimeUtc().addSecs(3600);

    const QVariantList googleByDisplay = db.getSnapshots(QStringLiteral("Google Gemini"), from, to);
    const QVariantList googleByDb = db.getSnapshots(QStringLiteral("Google"), from, to);

    QCOMPARE(googleByDisplay.size(), 0);
    QVERIFY(googleByDb.size() >= 1);

    const QVariantList xaiByDisplay = db.getSnapshots(QStringLiteral("xAI / Grok"), from, to);
    const QVariantList xaiByDb = db.getSnapshots(QStringLiteral("xAI"), from, to);

    QCOMPARE(xaiByDisplay.size(), 0);
    QVERIFY(xaiByDb.size() >= 1);
}

QTEST_MAIN(HistoryMappingRegressionTest)
#include "test_history_mapping_regression.moc"
