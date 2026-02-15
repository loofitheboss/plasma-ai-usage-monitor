#ifndef PROVIDERBACKEND_H
#define PROVIDERBACKEND_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QNetworkAccessManager>
#include <QNetworkReply>

/**
 * Abstract base class for AI provider backends.
 * Exposes usage, rate limits, and cost data to QML.
 * Each provider subclass implements its own API-specific logic.
 */
class ProviderBackend : public QObject
{
    Q_OBJECT

    // Identity
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString iconName READ iconName CONSTANT)

    // State
    Q_PROPERTY(bool connected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString error READ errorString NOTIFY errorChanged)

    // Usage data (primarily for OpenAI which has a usage API)
    Q_PROPERTY(qint64 inputTokens READ inputTokens NOTIFY dataUpdated)
    Q_PROPERTY(qint64 outputTokens READ outputTokens NOTIFY dataUpdated)
    Q_PROPERTY(qint64 totalTokens READ totalTokens NOTIFY dataUpdated)
    Q_PROPERTY(int requestCount READ requestCount NOTIFY dataUpdated)
    Q_PROPERTY(double cost READ cost NOTIFY dataUpdated)

    // Rate limits
    Q_PROPERTY(int rateLimitRequests READ rateLimitRequests NOTIFY dataUpdated)
    Q_PROPERTY(int rateLimitTokens READ rateLimitTokens NOTIFY dataUpdated)
    Q_PROPERTY(int rateLimitRequestsRemaining READ rateLimitRequestsRemaining NOTIFY dataUpdated)
    Q_PROPERTY(int rateLimitTokensRemaining READ rateLimitTokensRemaining NOTIFY dataUpdated)
    Q_PROPERTY(QString rateLimitResetTime READ rateLimitResetTime NOTIFY dataUpdated)

    // Metadata
    Q_PROPERTY(QDateTime lastRefreshed READ lastRefreshed NOTIFY dataUpdated)

public:
    explicit ProviderBackend(QObject *parent = nullptr);
    ~ProviderBackend() override;

    // Identity
    virtual QString name() const = 0;
    virtual QString iconName() const = 0;

    // State
    bool isConnected() const;
    bool isLoading() const;
    QString errorString() const;

    // Usage data
    qint64 inputTokens() const;
    qint64 outputTokens() const;
    qint64 totalTokens() const;
    int requestCount() const;
    double cost() const;

    // Rate limits
    int rateLimitRequests() const;
    int rateLimitTokens() const;
    int rateLimitRequestsRemaining() const;
    int rateLimitTokensRemaining() const;
    QString rateLimitResetTime() const;

    QDateTime lastRefreshed() const;

    // API key management
    Q_INVOKABLE void setApiKey(const QString &key);
    Q_INVOKABLE bool hasApiKey() const;

    // Data fetching
    Q_INVOKABLE virtual void refresh() = 0;

Q_SIGNALS:
    void connectedChanged();
    void loadingChanged();
    void errorChanged();
    void dataUpdated();
    void quotaWarning(const QString &provider, int percentUsed);

protected:
    void setConnected(bool connected);
    void setLoading(bool loading);
    void setError(const QString &error);
    void clearError();

    QNetworkAccessManager *networkManager() const;
    QString apiKey() const;

    // Data setters for subclasses
    void setInputTokens(qint64 tokens);
    void setOutputTokens(qint64 tokens);
    void setRequestCount(int count);
    void setCost(double cost);
    void setRateLimitRequests(int limit);
    void setRateLimitTokens(int limit);
    void setRateLimitRequestsRemaining(int remaining);
    void setRateLimitTokensRemaining(int remaining);
    void setRateLimitResetTime(const QString &time);
    void updateLastRefreshed();

    // Helper to parse rate limit headers common across providers
    void parseRateLimitHeaders(QNetworkReply *reply);

private:
    QNetworkAccessManager *m_networkManager;
    QString m_apiKey;

    bool m_connected = false;
    bool m_loading = false;
    QString m_error;

    qint64 m_inputTokens = 0;
    qint64 m_outputTokens = 0;
    int m_requestCount = 0;
    double m_cost = 0.0;

    int m_rateLimitRequests = 0;
    int m_rateLimitTokens = 0;
    int m_rateLimitRequestsRemaining = 0;
    int m_rateLimitTokensRemaining = 0;
    QString m_rateLimitResetTime;

    QDateTime m_lastRefreshed;
};

#endif // PROVIDERBACKEND_H
