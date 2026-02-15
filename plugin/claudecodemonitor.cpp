#include "claudecodemonitor.h"
#include <QStandardPaths>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>

ClaudeCodeMonitor::ClaudeCodeMonitor(QObject *parent)
    : SubscriptionToolBackend(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    connect(m_watcher, &QFileSystemWatcher::directoryChanged,
            this, &ClaudeCodeMonitor::onDirectoryChanged);
    connect(m_watcher, &QFileSystemWatcher::fileChanged,
            this, &ClaudeCodeMonitor::onFileChanged);
}

QString ClaudeCodeMonitor::claudeConfigDir() const
{
    // Claude Code stores config in ~/.claude/ by default
    // Can be overridden with CLAUDE_CONFIG_DIR env var
    QString envDir = QString::fromLocal8Bit(qgetenv("CLAUDE_CONFIG_DIR"));
    if (!envDir.isEmpty()) return envDir;
    return QDir::homePath() + QStringLiteral("/.claude");
}

void ClaudeCodeMonitor::checkToolInstalled()
{
    bool found = false;

    // Check if 'claude' binary exists in PATH
    QString claudePath = QStandardPaths::findExecutable(QStringLiteral("claude"));
    if (!claudePath.isEmpty()) {
        found = true;
    }

    // Also check for ~/.claude/ directory
    QDir configDir(claudeConfigDir());
    if (configDir.exists()) {
        found = true;
    }

    setInstalled(found);

    if (found && isEnabled()) {
        setupWatcher();
    }
}

void ClaudeCodeMonitor::setupWatcher()
{
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (dir.exists()) {
        m_watcher->addPath(configDir);

        // Watch key files that change during usage
        QString settingsFile = configDir + QStringLiteral("/settings.json");
        if (QFileInfo::exists(settingsFile)) {
            m_watcher->addPath(settingsFile);
        }

        // Watch projects directory for conversation activity
        QString projectsDir = configDir + QStringLiteral("/projects");
        if (QDir(projectsDir).exists()) {
            m_watcher->addPath(projectsDir);
        }
    }

    // Also watch ~/.claude.json (global state file)
    QString globalState = QDir::homePath() + QStringLiteral("/.claude.json");
    if (QFileInfo::exists(globalState)) {
        m_watcher->addPath(globalState);
    }
}

void ClaudeCodeMonitor::detectActivity()
{
    // Manually check for recent activity by looking at file modification times
    QString configDir = claudeConfigDir();
    QDir dir(configDir);

    if (!dir.exists()) return;

    QDateTime latestMod;

    // Check projects directory for recent changes
    QString projectsDir = configDir + QStringLiteral("/projects");
    QDir pDir(projectsDir);
    if (pDir.exists()) {
        const auto entries = pDir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot,
                                                 QDir::Time);
        if (!entries.isEmpty()) {
            latestMod = entries.first().lastModified();
        }
    }

    // Check global state file
    QFileInfo globalState(QDir::homePath() + QStringLiteral("/.claude.json"));
    if (globalState.exists() && globalState.lastModified() > latestMod) {
        latestMod = globalState.lastModified();
    }

    // If we see a new modification since last check, count it as activity
    if (latestMod.isValid() && latestMod > m_lastKnownModification) {
        m_lastKnownModification = latestMod;
        incrementUsage();
    }
}

void ClaudeCodeMonitor::onDirectoryChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;
    detectActivity();
}

void ClaudeCodeMonitor::onFileChanged(const QString &path)
{
    Q_UNUSED(path);
    if (!isEnabled()) return;

    // File changed — likely a conversation turn or config update
    QFileInfo fi(path);
    if (fi.exists() && fi.lastModified() > m_lastKnownModification) {
        m_lastKnownModification = fi.lastModified();
        incrementUsage();
    }

    // Re-add the file to the watcher (QFileSystemWatcher removes files after change)
    if (!m_watcher->files().contains(path) && QFileInfo::exists(path)) {
        m_watcher->addPath(path);
    }
}

QStringList ClaudeCodeMonitor::availablePlans() const
{
    return {
        QStringLiteral("Pro"),
        QStringLiteral("Max 5x"),
        QStringLiteral("Max 20x")
    };
}

int ClaudeCodeMonitor::defaultLimitForPlan(const QString &plan) const
{
    // 5-hour session limits (approximate, vary by message complexity)
    if (plan == QStringLiteral("Pro")) return 45;
    if (plan == QStringLiteral("Max 5x")) return 225;
    if (plan == QStringLiteral("Max 20x")) return 900;
    return 45;
}

int ClaudeCodeMonitor::defaultSecondaryLimitForPlan(const QString &plan) const
{
    // Weekly limits
    if (plan == QStringLiteral("Pro")) return 225;
    if (plan == QStringLiteral("Max 5x")) return 1125;
    if (plan == QStringLiteral("Max 20x")) return 4500;
    return 225;
}
