#include "anthropicprovider.h"
#include <QNetworkRequest>
#include <QDebug>

AnthropicProvider::AnthropicProvider(QObject *parent)
    : ProviderBackend(parent)
{
    // Register model pricing ($ per 1M tokens) — Anthropic pricing as of 2025
    registerModelPricing(QStringLiteral("claude-sonnet-4-20250514"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("claude-3-7-sonnet"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("claude-3-5-haiku"), 0.80, 4.0);
    registerModelPricing(QStringLiteral("claude-3-5-sonnet"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("claude-3-opus"), 15.0, 75.0);
    registerModelPricing(QStringLiteral("claude-3-haiku"), 0.25, 1.25);
}

QString AnthropicProvider::model() const { return m_model; }
void AnthropicProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

void AnthropicProvider::refresh()
{
    if (!hasApiKey()) {
        setError(QStringLiteral("No API key configured"));
        setConnected(false);
        return;
    }

    setLoading(true);
    clearError();
    fetchRateLimits();
}

void AnthropicProvider::fetchRateLimits()
{
    // Use the count_tokens endpoint as a lightweight way to get rate limit headers.
    // This is a minimal request that counts tokens for a tiny message.
    QUrl url(QStringLiteral("%1/messages/count_tokens").arg(effectiveBaseUrl(BASE_URL)));

    QNetworkRequest request(url);
    request.setRawHeader("x-api-key", apiKey().toUtf8());
    request.setRawHeader("anthropic-version", API_VERSION);
    request.setRawHeader("Content-Type", "application/json");

    // Minimal payload for count_tokens
    QJsonObject payload;
    payload.insert(QStringLiteral("model"), m_model);

    QJsonArray messages;
    QJsonObject msg;
    msg.insert(QStringLiteral("role"), QStringLiteral("user"));
    msg.insert(QStringLiteral("content"), QStringLiteral("hi"));
    messages.append(msg);
    payload.insert(QStringLiteral("messages"), messages);

    QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    QNetworkReply *reply = networkManager()->post(request, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onCountTokensReply(reply);
    });
}

void AnthropicProvider::onCountTokensReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (httpStatus == 401) {
            setError(QStringLiteral("Invalid API key"));
        } else if (httpStatus == 429) {
            setError(QStringLiteral("Rate limited"));
            // Still parse headers -- they're returned on 429 too
        } else {
            setError(QStringLiteral("API error: %1 (HTTP %2)")
                         .arg(reply->errorString())
                         .arg(httpStatus));
            setLoading(false);
            return;
        }
    }

    // Parse Anthropic's detailed rate limit headers
    auto readHeader = [&](const char *name) -> int {
        QByteArray val = reply->rawHeader(name);
        return val.isEmpty() ? 0 : val.toInt();
    };

    // Request limits
    int reqLimit = readHeader("anthropic-ratelimit-requests-limit");
    int reqRemaining = readHeader("anthropic-ratelimit-requests-remaining");
    QString reqReset = QString::fromUtf8(reply->rawHeader("anthropic-ratelimit-requests-reset"));

    // Input token limits
    int inputLimit = readHeader("anthropic-ratelimit-input-tokens-limit");
    int inputRemaining = readHeader("anthropic-ratelimit-input-tokens-remaining");

    // Output token limits
    int outputLimit = readHeader("anthropic-ratelimit-output-tokens-limit");
    int outputRemaining = readHeader("anthropic-ratelimit-output-tokens-remaining");

    // Set the primary rate limits (requests)
    if (reqLimit > 0) {
        setRateLimitRequests(reqLimit);
        setRateLimitRequestsRemaining(reqRemaining);
    }

    // Use the total token limits (input + output combined for display)
    // We show the larger of the two as the main token rate limit
    int tokenLimit = inputLimit + outputLimit;
    int tokenRemaining = inputRemaining + outputRemaining;
    if (tokenLimit > 0) {
        setRateLimitTokens(tokenLimit);
        setRateLimitTokensRemaining(tokenRemaining);
    }

    if (!reqReset.isEmpty()) {
        // Parse RFC 3339 timestamp to a readable time
        QDateTime resetDt = QDateTime::fromString(reqReset, Qt::ISODate);
        if (resetDt.isValid()) {
            setRateLimitResetTime(resetDt.toLocalTime().toString(QStringLiteral("hh:mm:ss")));
        } else {
            setRateLimitResetTime(reqReset);
        }
    }

    setConnected(true);
    setLoading(false);
    updateLastRefreshed();
    Q_EMIT dataUpdated();

    // Quota warning check
    if (reqLimit > 0) {
        int usedPercent = 100 - (reqRemaining * 100 / reqLimit);
        if (usedPercent >= 80) {
            Q_EMIT quotaWarning(name(), usedPercent);
        }
    }
}
