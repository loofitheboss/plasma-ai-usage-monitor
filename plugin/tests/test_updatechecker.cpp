#include <QtTest>
#include <QSignalSpy>

#include "updatechecker.h"

class UpdateCheckerTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void testSetCurrentVersion();
    void testSetCheckIntervalHours();
    void testCheckIntervalClamping();
    void testInitialState();
};

void UpdateCheckerTest::testSetCurrentVersion()
{
    UpdateChecker checker;
    QSignalSpy versionSpy(&checker, &UpdateChecker::currentVersionChanged);

    checker.setCurrentVersion(QStringLiteral("2.8.1"));
    QCOMPARE(checker.currentVersion(), QStringLiteral("2.8.1"));
    QCOMPARE(versionSpy.count(), 1);

    // Setting same value — no signal
    checker.setCurrentVersion(QStringLiteral("2.8.1"));
    QCOMPARE(versionSpy.count(), 1);

    // Setting different value — signal
    checker.setCurrentVersion(QStringLiteral("3.0.0"));
    QCOMPARE(versionSpy.count(), 2);
}

void UpdateCheckerTest::testSetCheckIntervalHours()
{
    UpdateChecker checker;
    QSignalSpy intervalSpy(&checker, &UpdateChecker::checkIntervalHoursChanged);

    QCOMPARE(checker.checkIntervalHours(), 12); // default

    checker.setCheckIntervalHours(24);
    QCOMPARE(checker.checkIntervalHours(), 24);
    QCOMPARE(intervalSpy.count(), 1);

    // Setting same value — no signal
    checker.setCheckIntervalHours(24);
    QCOMPARE(intervalSpy.count(), 1);
}

void UpdateCheckerTest::testCheckIntervalClamping()
{
    UpdateChecker checker;

    // Values < 1 should be clamped to 1
    checker.setCheckIntervalHours(0);
    QCOMPARE(checker.checkIntervalHours(), 1);

    checker.setCheckIntervalHours(-5);
    QCOMPARE(checker.checkIntervalHours(), 1);
}

void UpdateCheckerTest::testInitialState()
{
    UpdateChecker checker;
    QVERIFY(checker.currentVersion().isEmpty());
    QVERIFY(checker.latestVersion().isEmpty());
    QVERIFY(!checker.checking());
    QCOMPARE(checker.checkIntervalHours(), 12);
}

QTEST_MAIN(UpdateCheckerTest)
#include "test_updatechecker.moc"
