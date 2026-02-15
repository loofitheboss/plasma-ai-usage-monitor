#include "openaiprovider.h"
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QDateTime>
#include <QTimeZone>
#include <QDebug>

OpenAIProvider::OpenAIProvider(QObject *parent)
    : ProviderBackend(parent)
{
}

QString OpenAIProvider::projectId() const { return m_projectId; }
void OpenAIProvider::setProjectId(const QString &id)
{
    if (m_projectId != id) {
        m_projectId = id;
        Q_EMIT projectIdChanged();
    }
}

QString OpenAIProvider::model() const { return m_model; }
void OpenAIProvider::setModel(const QString &model)
{
    if (m_model != model) {
        m_model = model;
        Q_EMIT modelChanged();
    }
}

void OpenAIProvider::refresh()
{
    if (!hasApiKey()) {
        setError(QStringLiteral("No API key configured"));
        setConnected(false);
        return;
    }

    setLoading(true);
    clearError();
    m_pendingRequests = 0;

    fetchUsage();
    fetchCosts();
    fetchMonthlyCosts();
}

void OpenAIProvider::fetchUsage()
{
    // Query the last 24 hours of completion usage
    QDateTime now = QDateTime::currentDateTimeUtc();
    QDateTime dayAgo = now.addDays(-1);

    QUrl url(QStringLiteral("%1/organization/usage/completions").arg(effectiveBaseUrl(BASE_URL)));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("start_time"), QString::number(dayAgo.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("end_time"), QString::number(now.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("bucket_width"), QStringLiteral("1d"));

    // Add filters
    if (!m_model.isEmpty()) {
        query.addQueryItem(QStringLiteral("models"), m_model);
    }
    if (!m_projectId.isEmpty()) {
        query.addQueryItem(QStringLiteral("project_ids"), m_projectId);
    }

    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(apiKey()).toUtf8());
    request.setRawHeader("Content-Type", "application/json");

    m_pendingRequests++;
    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onUsageReply(reply);
    });
}

void OpenAIProvider::fetchCosts()
{
    QDateTime now = QDateTime::currentDateTimeUtc();
    QDateTime dayAgo = now.addDays(-1);

    QUrl url(QStringLiteral("%1/organization/costs").arg(effectiveBaseUrl(BASE_URL)));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("start_time"), QString::number(dayAgo.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("end_time"), QString::number(now.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("bucket_width"), QStringLiteral("1d"));

    if (!m_projectId.isEmpty()) {
        query.addQueryItem(QStringLiteral("project_ids"), m_projectId);
    }

    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(apiKey()).toUtf8());
    request.setRawHeader("Content-Type", "application/json");

    m_pendingRequests++;
    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onCostsReply(reply);
    });
}

void OpenAIProvider::onUsageReply(QNetworkReply *reply)
{
    reply->deleteLater();
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (httpStatus == 401 || httpStatus == 403) {
            setError(QStringLiteral("Authentication failed. Ensure you're using an Admin API key."));
        } else {
            setError(QStringLiteral("Usage API error: %1 (HTTP %2)")
                         .arg(reply->errorString())
                         .arg(httpStatus));
        }
        checkAllDone();
        return;
    }

    // Parse rate limit headers from the response
    auto readHeader = [&](const char *name) -> int {
        QByteArray val = reply->rawHeader(name);
        return val.isEmpty() ? 0 : val.toInt();
    };

    int rlRequests = readHeader("x-ratelimit-limit-requests");
    int rlTokens = readHeader("x-ratelimit-limit-tokens");
    int rlReqRemaining = readHeader("x-ratelimit-remaining-requests");
    int rlTokRemaining = readHeader("x-ratelimit-remaining-tokens");
    QString rlResetReq = QString::fromUtf8(reply->rawHeader("x-ratelimit-reset-requests"));

    if (rlRequests > 0) {
        setRateLimitRequests(rlRequests);
        setRateLimitRequestsRemaining(rlReqRemaining); // Can be 0 when fully depleted
    }
    if (rlTokens > 0) {
        setRateLimitTokens(rlTokens);
        setRateLimitTokensRemaining(rlTokRemaining); // Can be 0 when fully depleted
    }
    if (!rlResetReq.isEmpty()) setRateLimitResetTime(rlResetReq);

    // Parse JSON body
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        setError(QStringLiteral("Failed to parse usage response"));
        checkAllDone();
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray buckets = root.value(QStringLiteral("data")).toArray();

    qint64 totalInput = 0;
    qint64 totalOutput = 0;
    int totalRequests = 0;

    for (const QJsonValue &bucket : buckets) {
        QJsonArray results = bucket.toObject().value(QStringLiteral("result")).toArray();
        for (const QJsonValue &result : results) {
            QJsonObject r = result.toObject();
            totalInput += r.value(QStringLiteral("input_tokens")).toInteger(0);
            totalOutput += r.value(QStringLiteral("output_tokens")).toInteger(0);
            totalRequests += r.value(QStringLiteral("num_model_requests")).toInt(0);
        }
    }

    setInputTokens(totalInput);
    setOutputTokens(totalOutput);
    setRequestCount(totalRequests);
    setConnected(true);

    checkAllDone();
}

void OpenAIProvider::onCostsReply(QNetworkReply *reply)
{
    reply->deleteLater();
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        // Non-fatal: usage data may still be available
        qWarning() << "AI Usage Monitor: OpenAI costs API error:" << reply->errorString();
        checkAllDone();
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        checkAllDone();
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray buckets = root.value(QStringLiteral("data")).toArray();

    double totalCost = 0.0;
    for (const QJsonValue &bucket : buckets) {
        QJsonArray results = bucket.toObject().value(QStringLiteral("result")).toArray();
        for (const QJsonValue &result : results) {
            QJsonObject r = result.toObject();
            // Cost is in cents, convert to dollars
            totalCost += r.value(QStringLiteral("amount")).toDouble(0.0);
        }
    }

    double costDollars = totalCost / 100.0; // API returns cents
    setCost(costDollars);
    setDailyCost(costDollars); // 24h window = daily cost
    checkAllDone();
}

void OpenAIProvider::fetchMonthlyCosts()
{
    // Query costs from the start of the current month
    QDateTime now = QDateTime::currentDateTimeUtc();
    QDate today = now.date();
    QDate monthStart(today.year(), today.month(), 1);
    QDateTime monthStartDt(monthStart.startOfDay(QTimeZone::UTC));

    QUrl url(QStringLiteral("%1/organization/costs").arg(effectiveBaseUrl(BASE_URL)));
    QUrlQuery query;
    query.addQueryItem(QStringLiteral("start_time"), QString::number(monthStartDt.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("end_time"), QString::number(now.toSecsSinceEpoch()));
    query.addQueryItem(QStringLiteral("bucket_width"), QStringLiteral("1d"));

    if (!m_projectId.isEmpty()) {
        query.addQueryItem(QStringLiteral("project_ids"), m_projectId);
    }

    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Authorization", QStringLiteral("Bearer %1").arg(apiKey()).toUtf8());
    request.setRawHeader("Content-Type", "application/json");

    m_pendingRequests++;
    QNetworkReply *reply = networkManager()->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onMonthlyCostsReply(reply);
    });
}

void OpenAIProvider::onMonthlyCostsReply(QNetworkReply *reply)
{
    reply->deleteLater();
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        // Non-fatal: daily cost data may still be available
        qWarning() << "AI Usage Monitor: OpenAI monthly costs API error:" << reply->errorString();
        checkAllDone();
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        checkAllDone();
        return;
    }

    QJsonObject root = doc.object();
    QJsonArray buckets = root.value(QStringLiteral("data")).toArray();

    double totalCost = 0.0;
    for (const QJsonValue &bucket : buckets) {
        QJsonArray results = bucket.toObject().value(QStringLiteral("result")).toArray();
        for (const QJsonValue &result : results) {
            QJsonObject r = result.toObject();
            totalCost += r.value(QStringLiteral("amount")).toDouble(0.0);
        }
    }

    double costDollars = totalCost / 100.0; // API returns cents
    setMonthlyCost(costDollars);
    checkAllDone();
}

void OpenAIProvider::checkAllDone()
{
    if (m_pendingRequests <= 0) {
        setLoading(false);
        updateLastRefreshed();
        Q_EMIT dataUpdated();

        // Check for quota warnings
        if (rateLimitRequests() > 0) {
            int usedPercent = 100 - (rateLimitRequestsRemaining() * 100 / rateLimitRequests());
            if (usedPercent >= 80) {
                Q_EMIT quotaWarning(name(), usedPercent);
            }
        }
    }
}
