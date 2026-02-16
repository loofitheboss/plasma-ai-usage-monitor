#include "updatechecker.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QUrl>
#include <QDebug>

UpdateChecker::UpdateChecker(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
    , m_timer(new QTimer(this))
{
    m_timer->setSingleShot(false);
    connect(m_timer, &QTimer::timeout, this, &UpdateChecker::checkForUpdate);
}

// ── Properties ──

QString UpdateChecker::currentVersion() const { return m_currentVersion; }
void UpdateChecker::setCurrentVersion(const QString &v)
{
    if (m_currentVersion != v) {
        m_currentVersion = v;
        Q_EMIT currentVersionChanged();
        startTimerIfReady();
    }
}

int UpdateChecker::checkIntervalHours() const { return m_intervalHours; }
void UpdateChecker::setCheckIntervalHours(int h)
{
    if (h < 1) h = 1;
    if (m_intervalHours != h) {
        m_intervalHours = h;
        Q_EMIT checkIntervalHoursChanged();
        startTimerIfReady();
    }
}

bool UpdateChecker::checking() const { return m_checking; }
QString UpdateChecker::latestVersion() const { return m_latestVersion; }

// ── Update Check ──

void UpdateChecker::checkForUpdate()
{
    if (m_checking) return;

    m_checking = true;
    Q_EMIT checkingChanged();

    QNetworkRequest req(QUrl(
        QStringLiteral("https://api.github.com/repos/loofitheboss/plasma-ai-usage-monitor/releases/latest")));
    req.setTransferTimeout(30000);
    req.setRawHeader("Accept", "application/vnd.github+json");
    req.setRawHeader("User-Agent", "plasma-ai-usage-monitor/" + m_currentVersion.toUtf8());

    QNetworkReply *reply = m_nam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        m_checking = false;
        Q_EMIT checkingChanged();

        if (reply->error() != QNetworkReply::NoError) {
            qWarning() << "UpdateChecker: network error:" << reply->errorString();
            return;
        }

        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        if (!doc.isObject()) return;

        const QJsonObject obj = doc.object();
        QString tagName = obj.value(QStringLiteral("tag_name")).toString();
        const QString htmlUrl = obj.value(QStringLiteral("html_url")).toString();

        // Strip leading 'v' from tag
        if (tagName.startsWith(QLatin1Char('v')) || tagName.startsWith(QLatin1Char('V')))
            tagName = tagName.mid(1);

        const QVersionNumber remote = QVersionNumber::fromString(tagName);
        const QVersionNumber local  = QVersionNumber::fromString(m_currentVersion);

        if (remote.isNull() || local.isNull()) return;

        m_latestVersion = tagName;
        Q_EMIT latestVersionChanged();

        if (remote > local) {
            Q_EMIT updateAvailable(tagName, htmlUrl);
        }
    });
}

// ── Private ──

void UpdateChecker::startTimerIfReady()
{
    if (m_currentVersion.isEmpty()) return;
    m_timer->setInterval(m_intervalHours * 3600 * 1000);
    if (!m_timer->isActive()) {
        m_timer->start();
        // Also do an immediate first check (with short delay to let QML finish loading)
        QTimer::singleShot(5000, this, &UpdateChecker::checkForUpdate);
    }
}
