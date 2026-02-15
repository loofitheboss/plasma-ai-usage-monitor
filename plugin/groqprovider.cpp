#include "groqprovider.h"
#include <QNetworkRequest>
#include <QDebug>

GroqProvider::GroqProvider(QObject *parent)
    : ProviderBackend(parent)
{
}

QString GroqProvider::model() const { return m_model; }
void GroqProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

void GroqProvider::refresh()
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

void GroqProvider::fetchRateLimits()
{
    // Use minimal chat completion to read rate limit headers
    QUrl url(QStringLiteral("%1/chat/completions").arg(effectiveBaseUrl(BASE_URL)));

    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(apiKey()).toUtf8());
    request.setRawHeader("Content-Type", "application/json");

    QJsonObject payload;
    payload.insert(QStringLiteral("model"), m_model);
    payload.insert(QStringLiteral("max_tokens"), 1);

    QJsonArray messages;
    QJsonObject msg;
    msg.insert(QStringLiteral("role"), QStringLiteral("user"));
    msg.insert(QStringLiteral("content"), QStringLiteral("hi"));
    messages.append(msg);
    payload.insert(QStringLiteral("messages"), messages);

    QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    QNetworkReply *reply = networkManager()->post(request, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onCompletionReply(reply);
    });
}

void GroqProvider::onCompletionReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (httpStatus == 401) {
            setError(QStringLiteral("Invalid API key"));
        } else if (httpStatus == 429) {
            setError(QStringLiteral("Rate limited"));
            // Still parse headers on 429
        } else {
            setError(QStringLiteral("API error: %1 (HTTP %2)")
                         .arg(reply->errorString())
                         .arg(httpStatus));
            setLoading(false);
            setConnected(false);
            Q_EMIT dataUpdated();
            return;
        }
    }

    // Parse Groq rate limit headers (OpenAI-compatible)
    auto readHeader = [&](const char *name) -> int {
        QByteArray val = reply->rawHeader(name);
        return val.isEmpty() ? 0 : val.toInt();
    };

    int rlRequests = readHeader("x-ratelimit-limit-requests");
    int rlTokens = readHeader("x-ratelimit-limit-tokens");
    int rlReqRemaining = readHeader("x-ratelimit-remaining-requests");
    int rlTokRemaining = readHeader("x-ratelimit-remaining-tokens");
    QString rlReset = QString::fromUtf8(reply->rawHeader("x-ratelimit-reset-requests"));

    if (rlRequests > 0) {
        setRateLimitRequests(rlRequests);
        setRateLimitRequestsRemaining(rlReqRemaining);
    }
    if (rlTokens > 0) {
        setRateLimitTokens(rlTokens);
        setRateLimitTokensRemaining(rlTokRemaining);
    }
    if (!rlReset.isEmpty()) {
        setRateLimitResetTime(rlReset);
    }

    // Parse usage from response body
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isNull()) {
        QJsonObject root = doc.object();
        QJsonObject usage = root.value(QStringLiteral("usage")).toObject();
        if (!usage.isEmpty()) {
            // Groq returns detailed usage including queue_time, prompt_time, completion_time
            qint64 promptTokens = usage.value(QStringLiteral("prompt_tokens")).toInteger(0);
            qint64 completionTokens = usage.value(QStringLiteral("completion_tokens")).toInteger(0);
            Q_UNUSED(promptTokens);
            Q_UNUSED(completionTokens);
        }
    }

    setConnected(true);
    setLoading(false);
    updateLastRefreshed();
    Q_EMIT dataUpdated();

    // Quota warning check
    if (rateLimitRequests() > 0) {
        int usedPercent = 100 - (rateLimitRequestsRemaining() * 100 / rateLimitRequests());
        if (usedPercent >= 80) {
            Q_EMIT quotaWarning(name(), usedPercent);
        }
    }
}
