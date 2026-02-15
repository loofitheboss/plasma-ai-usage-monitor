#ifndef PROVIDERBACKEND_H
#define PROVIDERBACKEND_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QNetworkAccessManager>
#include <QNetworkReply>

/**
 * Abstract base class for AI provider backends.
 * Exposes usage, rate limits, cost data, and budget tracking to QML.
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
    Q_PROPERTY(int errorCount READ errorCount NOTIFY errorChanged)
    Q_PROPERTY(int consecutiveErrors READ consecutiveErrors NOTIFY errorChanged)

    // Usage data
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

    // Budget tracking
    Q_PROPERTY(double dailyBudget READ dailyBudget WRITE setDailyBudget NOTIFY budgetChanged)
    Q_PROPERTY(double monthlyBudget READ monthlyBudget WRITE setMonthlyBudget NOTIFY budgetChanged)
    Q_PROPERTY(double dailyCost READ dailyCost NOTIFY dataUpdated)
    Q_PROPERTY(double monthlyCost READ monthlyCost NOTIFY dataUpdated)
    Q_PROPERTY(double estimatedMonthlyCost READ estimatedMonthlyCost NOTIFY dataUpdated)

    // Custom base URL (proxy support)
    Q_PROPERTY(QString customBaseUrl READ customBaseUrl WRITE setCustomBaseUrl NOTIFY customBaseUrlChanged)

    // Metadata
    Q_PROPERTY(QDateTime lastRefreshed READ lastRefreshed NOTIFY dataUpdated)
    Q_PROPERTY(int refreshCount READ refreshCount NOTIFY dataUpdated)

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
    int errorCount() const;
    int consecutiveErrors() const;

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

    // Budget
    double dailyBudget() const;
    double monthlyBudget() const;
    void setDailyBudget(double budget);
    void setMonthlyBudget(double budget);
    double dailyCost() const;
    double monthlyCost() const;
    double estimatedMonthlyCost() const;

    // Custom URL
    QString customBaseUrl() const;
    void setCustomBaseUrl(const QString &url);

    // Metadata
    QDateTime lastRefreshed() const;
    int refreshCount() const;

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
    void budgetChanged();
    void budgetExceeded(const QString &provider, const QString &period, double spent, double budget);
    void customBaseUrlChanged();
    void providerDisconnected(const QString &provider);
    void providerReconnected(const QString &provider);

protected:
    void setConnected(bool connected);
    void setLoading(bool loading);
    void setError(const QString &error);
    void clearError();

    QNetworkAccessManager *networkManager() const;
    QString apiKey() const;
    QString effectiveBaseUrl(const char *defaultUrl) const;

    // Data setters for subclasses
    void setInputTokens(qint64 tokens);
    void setOutputTokens(qint64 tokens);
    void setRequestCount(int count);
    void setCost(double cost);
    void setDailyCost(double cost);
    void setMonthlyCost(double cost);
    void setRateLimitRequests(int limit);
    void setRateLimitTokens(int limit);
    void setRateLimitRequestsRemaining(int remaining);
    void setRateLimitTokensRemaining(int remaining);
    void setRateLimitResetTime(const QString &time);
    void updateLastRefreshed();

    // Budget checking after cost update
    void checkBudgetLimits();

private:
    QNetworkAccessManager *m_networkManager;
    QString m_apiKey;
    QString m_customBaseUrl;

    bool m_connected = false;
    bool m_loading = false;
    QString m_error;
    int m_errorCount = 0;
    int m_consecutiveErrors = 0;

    qint64 m_inputTokens = 0;
    qint64 m_outputTokens = 0;
    int m_requestCount = 0;
    double m_cost = 0.0;
    double m_dailyCost = 0.0;
    double m_monthlyCost = 0.0;

    double m_dailyBudget = 0.0;
    double m_monthlyBudget = 0.0;

    int m_rateLimitRequests = 0;
    int m_rateLimitTokens = 0;
    int m_rateLimitRequestsRemaining = 0;
    int m_rateLimitTokensRemaining = 0;
    QString m_rateLimitResetTime;

    QDateTime m_lastRefreshed;
    int m_refreshCount = 0;
    bool m_wasConnected = false; // for disconnect/reconnect tracking
};

#endif // PROVIDERBACKEND_H
