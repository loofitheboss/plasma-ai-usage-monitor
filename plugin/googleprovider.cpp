#include "googleprovider.h"
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QDebug>

GoogleProvider::GoogleProvider(QObject *parent)
    : ProviderBackend(parent)
{
}

QString GoogleProvider::model() const { return m_model; }
void GoogleProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

void GoogleProvider::refresh()
{
    if (!hasApiKey()) {
        setError(QStringLiteral("No API key configured"));
        setConnected(false);
        return;
    }

    setLoading(true);
    clearError();
    fetchStatus();
}

void GoogleProvider::fetchStatus()
{
    // Use countTokens as a lightweight connectivity check
    QUrl url(QStringLiteral("%1/models/%2:countTokens")
                 .arg(QLatin1String(BASE_URL), m_model));

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("key"), apiKey());
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Content-Type", "application/json");

    // Minimal payload
    QJsonObject payload;
    QJsonArray contents;
    QJsonObject content;
    QJsonArray parts;
    QJsonObject part;
    part.insert(QStringLiteral("text"), QStringLiteral("hi"));
    parts.append(part);
    content.insert(QStringLiteral("parts"), parts);
    contents.append(content);
    payload.insert(QStringLiteral("contents"), contents);

    QByteArray body = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    QNetworkReply *reply = networkManager()->post(request, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onCountTokensReply(reply);
    });
}

void GoogleProvider::onCountTokensReply(QNetworkReply *reply)
{
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (httpStatus == 400) {
            setError(QStringLiteral("Invalid API key or model name"));
        } else if (httpStatus == 429) {
            setError(QStringLiteral("Rate limited"));
        } else {
            setError(QStringLiteral("API error: %1 (HTTP %2)")
                         .arg(reply->errorString())
                         .arg(httpStatus));
        }
        setLoading(false);
        setConnected(false);
        Q_EMIT dataUpdated();
        return;
    }

    // Parse response for basic verification
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isNull()) {
        QJsonObject root = doc.object();
        // The countTokens response has totalTokens -- we don't use it,
        // but a successful response confirms the key works.
        int totalTokens = root.value(QStringLiteral("totalTokens")).toInt(0);
        Q_UNUSED(totalTokens);
    }

    // Google doesn't expose rate limit headers on the Gemini API,
    // so we apply known documentation limits.
    applyKnownLimits();

    setConnected(true);
    setLoading(false);
    updateLastRefreshed();
    Q_EMIT dataUpdated();
}

void GoogleProvider::applyKnownLimits()
{
    // Known free-tier limits for Gemini API (as of 2025)
    // These are approximate and depend on model/tier.
    // Users on paid tiers will have higher limits.
    //
    // Gemini 2.0 Flash free tier:
    //   15 RPM, 1M TPM, 1500 RPD
    // Gemini 2.0 Flash paid tier:
    //   2000 RPM, 4M TPM

    if (m_model.contains(QStringLiteral("flash"))) {
        setRateLimitRequests(15);  // RPM for free tier
        setRateLimitRequestsRemaining(15); // Unknown, show full
        setRateLimitTokens(1000000); // 1M TPM
        setRateLimitTokensRemaining(1000000);
    } else if (m_model.contains(QStringLiteral("pro"))) {
        setRateLimitRequests(2);
        setRateLimitRequestsRemaining(2);
        setRateLimitTokens(32000);
        setRateLimitTokensRemaining(32000);
    } else {
        // Generic defaults
        setRateLimitRequests(15);
        setRateLimitRequestsRemaining(15);
        setRateLimitTokens(1000000);
        setRateLimitTokensRemaining(1000000);
    }

    setRateLimitResetTime(QStringLiteral("N/A (static limits)"));
}
