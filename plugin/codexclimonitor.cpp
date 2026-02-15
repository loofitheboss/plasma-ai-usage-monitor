#include "codexclimonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QDebug>

CodexCliMonitor::CodexCliMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &CodexCliMonitor::onDirectoryChanged);
}

QString CodexCliMonitor::codexConfigDir() const
{
    // Codex CLI stores config in ~/.codex/
    return QDir::homePath() + QStringLiteral("/.codex");
}

void CodexCliMonitor::checkToolInstalled()
{
    bool found = false;

    // Check if 'codex' binary exists in PATH
    QString codexPath = QStandardPaths::findExecutable(QStringLiteral("codex"));
    if (!codexPath.isEmpty()) {
        found = true;
    }

    // Also check for ~/.codex/ directory
    QDir configDir(codexConfigDir());
    if (configDir.exists()) {
        found = true;
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void CodexCliMonitor::setupWatcher()
{
    QString configDir = codexConfigDir();
    QDir dir(configDir);

    if (dir.exists()) {
        m_watcher->addPath(configDir);

        // Watch subdirectories for session activity
        const auto subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const auto &subdir : subdirs) {
            m_watcher->addPath(subdir.absoluteFilePath());
        }
    }
}

void CodexCliMonitor::detectActivity()
{
    QString configDir = codexConfigDir();
    QDir dir(configDir);

    if (!dir.exists()) return;

    QDateTime latestMod;

    // Check all files in the codex directory for recent modifications
    const auto entries = dir.entryInfoList(QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot,
                                            QDir::Time);
    if (!entries.isEmpty()) {
        latestMod = entries.first().lastModified();
    }

    if (latestMod.isValid() && latestMod > m_lastKnownModification) {
        m_lastKnownModification = latestMod;
        incrementUsage();
    }
}

void CodexCliMonitor::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();
}

QStringList CodexCliMonitor::availablePlans() const
{
    return {
        QStringLiteral("Plus"),
        QStringLiteral("Pro"),
        QStringLiteral("Business")
    };
}

int CodexCliMonitor::defaultLimitForPlan(const QString &plan) const
{
    // Lower bound of 5-hour window for local messages
    if (plan == QStringLiteral("Plus")) return 45;
    if (plan == QStringLiteral("Pro")) return 300;
    if (plan == QStringLiteral("Business")) return 45;
    return 45;
}
