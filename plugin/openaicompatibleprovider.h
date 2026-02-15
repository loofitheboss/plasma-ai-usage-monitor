#ifndef OPENAICOMPATIBLEPROVIDER_H
#define OPENAICOMPATIBLEPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * Base class for OpenAI-compatible provider backends.
 *
 * Handles the common pattern of:
 * - POST /chat/completions with max_tokens=1 to read rate limit headers
 * - Parsing x-ratelimit-* response headers
 * - Parsing usage object from response body (tokens)
 * - Accumulating token counts across refreshes
 *
 * Subclasses must provide: name(), iconName(), defaultModel(), baseUrl()
 * Subclasses can override refresh() to add extra API calls (e.g., balance endpoint)
 */
class OpenAICompatibleProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit OpenAICompatibleProvider(QObject *parent = nullptr);

    QString model() const;
    void setModel(const QString &model);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();

protected:
    /// The default base URL for this provider (e.g., "https://api.groq.com/openai/v1")
    virtual const char *defaultBaseUrl() const = 0;

    /// Called when the chat completion request finishes successfully.
    /// Base implementation parses rate limits and usage. Override to add extra logic.
    virtual void onCompletionFinished(QNetworkReply *reply);

    /// Called when all pending requests are done (for multi-request providers)
    virtual void onAllRequestsDone();

    /// Increment/decrement pending request counter (for subclasses like DeepSeek)
    void addPendingRequest();
    bool decrementPendingRequest();

private:
    void fetchRateLimits();
    void parseRateLimitHeaders(QNetworkReply *reply);
    void parseUsageBody(QNetworkReply *reply);

    QString m_model;
    int m_pendingRequests = 0;
};

#endif // OPENAICOMPATIBLEPROVIDER_H
