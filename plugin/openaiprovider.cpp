#include "openaiprovider.h"
#include <KLocalizedString>
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
        setError(i18n("No API key configured"));
        setConnected(false);
        return;
    }

    beginRefresh();
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

    QNetworkRequest request = createRequest(url);

    m_pendingRequests++;
    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
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

    QNetworkRequest request = createRequest(url);

    m_pendingRequests++;
    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
        onCostsReply(reply);
    });
}

void OpenAIProvider::onUsageReply(QNetworkReply *reply)
{
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        // Retry transient errors (retryRequest takes ownership of reply)
        if (isRetryableStatus(httpStatus)) {
            m_pendingRequests++; // re-increment since retry is pending
            retryRequest(reply, reply->url(), QByteArray(),
                         [this](QNetworkReply *r) { onUsageReply(r); });
            return;
        }

        reply->deleteLater();

        if (httpStatus == 401 || httpStatus == 403) {
            setError(i18n("Authentication failed. Ensure you're using an Admin API key."));
        } else {
            setError(i18n("Usage API error: %1 (HTTP %2)",
                         reply->errorString(),
                         QString::number(httpStatus)));
        }
        checkAllDone();
        return;
    }

    reply->deleteLater();

    // Parse rate limit headers from the response
    parseRateLimitHeaders(reply);

    // Parse JSON body
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (doc.isNull()) {
        setError(i18n("Failed to parse usage response"));
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
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        // Retry transient errors (retryRequest takes ownership of reply)
        if (isRetryableStatus(httpStatus)) {
            m_pendingRequests++; // re-increment since retry is pending
            retryRequest(reply, reply->url(), QByteArray(),
                         [this](QNetworkReply *r) { onCostsReply(r); });
            return;
        }

        // Non-fatal: usage data may still be available
        qWarning() << "AI Usage Monitor: OpenAI costs API error:" << reply->errorString();
        reply->deleteLater();
        checkAllDone();
        return;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();
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

    QNetworkRequest request = createRequest(url);

    m_pendingRequests++;
    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
        onMonthlyCostsReply(reply);
    });
}

void OpenAIProvider::onMonthlyCostsReply(QNetworkReply *reply)
{
    m_pendingRequests--;

    if (reply->error() != QNetworkReply::NoError) {
        int httpStatus = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        // Retry transient errors (retryRequest takes ownership of reply)
        if (isRetryableStatus(httpStatus)) {
            m_pendingRequests++; // re-increment since retry is pending
            retryRequest(reply, reply->url(), QByteArray(),
                         [this](QNetworkReply *r) { onMonthlyCostsReply(r); });
            return;
        }

        // Non-fatal: daily cost data may still be available
        qWarning() << "AI Usage Monitor: OpenAI monthly costs API error:" << reply->errorString();
        reply->deleteLater();
        checkAllDone();
        return;
    }

    QByteArray data = reply->readAll();
    reply->deleteLater();
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
