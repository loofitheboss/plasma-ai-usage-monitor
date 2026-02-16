#include "openaicompatibleprovider.h"
#include <KLocalizedString>
#include <QNetworkRequest>
#include <QDebug>

OpenAICompatibleProvider::OpenAICompatibleProvider(QObject *parent)
    : ProviderBackend(parent)
{
}

QString OpenAICompatibleProvider::model() const { return m_model; }
void OpenAICompatibleProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

void OpenAICompatibleProvider::refresh()
{
    if (!hasApiKey()) {
        setError(i18n("No API key configured"));
        setConnected(false);
        return;
    }

    beginRefresh();
    setLoading(true);
    clearError();
    m_pendingRequests = 0;
    fetchRateLimits();
}

void OpenAICompatibleProvider::fetchRateLimits()
{
    // Use minimal chat completion to read rate limit headers
    QUrl url(QStringLiteral("%1/chat/completions").arg(effectiveBaseUrl(defaultBaseUrl())));

    QNetworkRequest request = createRequest(url);

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
    m_lastRequestBody = body;

    addPendingRequest();
    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->post(request, body);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
        onCompletionFinished(reply);
    });
}

void OpenAICompatibleProvider::parseRateLimitHeaders(QNetworkReply *reply)
{
    // Delegate to centralized base class parser
    ProviderBackend::parseRateLimitHeaders(reply, "x-ratelimit-");
}

void OpenAICompatibleProvider::parseUsageBody(QNetworkReply *reply)
{
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isNull()) {
        QJsonObject root = doc.object();
        QJsonObject usage = root.value(QStringLiteral("usage")).toObject();
        if (!usage.isEmpty()) {
            qint64 promptTokens = usage.value(QStringLiteral("prompt_tokens")).toInteger(0);
            qint64 completionTokens = usage.value(QStringLiteral("completion_tokens")).toInteger(0);
            // Track tokens from this refresh only (not accumulated)
            // The monitoring request itself uses ~1 token; accumulating would
            // inflate counts across refreshes and misrepresent actual usage.
            m_sessionInputTokens += promptTokens;
            m_sessionOutputTokens += completionTokens;
            m_sessionRequestCount++;
            setInputTokens(m_sessionInputTokens);
            setOutputTokens(m_sessionOutputTokens);
            setRequestCount(m_sessionRequestCount);
        }
    }
}

void OpenAICompatibleProvider::onCompletionFinished(QNetworkReply *reply)
{
    decrementPendingRequest();

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        // Retry transient errors (retryRequest takes ownership of reply)
        if (isRetryableStatus(httpStatus)) {
            addPendingRequest(); // re-increment since retry is pending
            retryRequest(reply, reply->url(), m_lastRequestBody,
                         [this](QNetworkReply *r) { onCompletionFinished(r); });
            return;
        }

        if (httpStatus == 401) {
            setError(i18n("Invalid API key"));
        } else if (httpStatus == 429) {
            setError(i18n("Rate limited"));
            // Still parse headers on 429
            parseRateLimitHeaders(reply);
        } else {
            setError(i18n("API error: %1 (HTTP %2)",
                         reply->errorString(),
                         QString::number(httpStatus)));
        }

        reply->deleteLater();

        if (httpStatus != 429 && httpStatus != 401) {
            onAllRequestsDone();
            return;
        }
    } else {
        parseRateLimitHeaders(reply);
        parseUsageBody(reply);
        reply->deleteLater();
        setConnected(true);

        // Update estimated cost based on accumulated tokens
        updateEstimatedCost(m_model);
    }

    onAllRequestsDone();
}

void OpenAICompatibleProvider::onAllRequestsDone()
{
    if (m_pendingRequests <= 0) {
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
}

void OpenAICompatibleProvider::addPendingRequest()
{
    m_pendingRequests++;
}

bool OpenAICompatibleProvider::decrementPendingRequest()
{
    m_pendingRequests--;
    return m_pendingRequests <= 0;
}
