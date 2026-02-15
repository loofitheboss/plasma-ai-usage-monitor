#ifndef UPDATECHECKER_H
#define UPDATECHECKER_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>
#include <QVersionNumber>
#include <QUrl>

/**
 * Periodically checks GitHub releases for newer versions and emits
 * updateAvailable() so QML can fire a KDE notification.
 *
 * Usage from QML:
 *   UpdateChecker {
 *       currentVersion: "2.1.0"
 *       checkIntervalHours: 12
 *       onUpdateAvailable: (latestVersion, releaseUrl) => { ... }
 *   }
 */
class UpdateChecker : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentVersion READ currentVersion WRITE setCurrentVersion NOTIFY currentVersionChanged)
    Q_PROPERTY(int checkIntervalHours READ checkIntervalHours WRITE setCheckIntervalHours NOTIFY checkIntervalHoursChanged)
    Q_PROPERTY(bool checking READ checking NOTIFY checkingChanged)
    Q_PROPERTY(QString latestVersion READ latestVersion NOTIFY latestVersionChanged)

public:
    explicit UpdateChecker(QObject *parent = nullptr)
        : QObject(parent)
        , m_nam(new QNetworkAccessManager(this))
        , m_timer(new QTimer(this))
    {
        m_timer->setSingleShot(false);
        connect(m_timer, &QTimer::timeout, this, &UpdateChecker::checkForUpdate);
    }

    // ── Properties ──

    QString currentVersion() const { return m_currentVersion; }
    void setCurrentVersion(const QString &v) {
        if (m_currentVersion != v) {
            m_currentVersion = v;
            Q_EMIT currentVersionChanged();
            // Start timer once version is known
            startTimerIfReady();
        }
    }

    int checkIntervalHours() const { return m_intervalHours; }
    void setCheckIntervalHours(int h) {
        if (h < 1) h = 1;
        if (m_intervalHours != h) {
            m_intervalHours = h;
            Q_EMIT checkIntervalHoursChanged();
            startTimerIfReady();
        }
    }

    bool checking() const { return m_checking; }
    QString latestVersion() const { return m_latestVersion; }

    /// Trigger a manual check (callable from QML)
    Q_INVOKABLE void checkForUpdate()
    {
        if (m_checking) return;

        m_checking = true;
        Q_EMIT checkingChanged();

        QNetworkRequest req(QUrl(
            QStringLiteral("https://api.github.com/repos/loofitheboss/plasma-ai-usage-monitor/releases/latest")));
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

Q_SIGNALS:
    void currentVersionChanged();
    void checkIntervalHoursChanged();
    void checkingChanged();
    void latestVersionChanged();
    void updateAvailable(const QString &latestVersion, const QString &releaseUrl);

private:
    void startTimerIfReady()
    {
        if (m_currentVersion.isEmpty()) return;
        m_timer->setInterval(m_intervalHours * 3600 * 1000);
        if (!m_timer->isActive()) {
            m_timer->start();
            // Also do an immediate first check (with short delay to let QML finish loading)
            QTimer::singleShot(5000, this, &UpdateChecker::checkForUpdate);
        }
    }

    QNetworkAccessManager *m_nam = nullptr;
    QTimer *m_timer = nullptr;
    QString m_currentVersion;
    QString m_latestVersion;
    int m_intervalHours = 12;
    bool m_checking = false;
};

#endif // UPDATECHECKER_H
