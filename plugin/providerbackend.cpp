#include "providerbackend.h"
#include <QDate>

ProviderBackend::ProviderBackend(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
}

ProviderBackend::~ProviderBackend() = default;

// --- State ---

bool ProviderBackend::isConnected() const { return m_connected; }
bool ProviderBackend::isLoading() const { return m_loading; }
QString ProviderBackend::errorString() const { return m_error; }
int ProviderBackend::errorCount() const { return m_errorCount; }
int ProviderBackend::consecutiveErrors() const { return m_consecutiveErrors; }

void ProviderBackend::setConnected(bool connected)
{
    if (m_connected != connected) {
        bool wasConnected = m_connected;
        m_connected = connected;
        Q_EMIT connectedChanged();

        // Track disconnect/reconnect events
        if (wasConnected && !connected) {
            Q_EMIT providerDisconnected(name());
        } else if (!wasConnected && connected && m_wasConnected) {
            Q_EMIT providerReconnected(name());
        }
        m_wasConnected = m_wasConnected || connected;
    }
}

void ProviderBackend::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        Q_EMIT loadingChanged();
    }
}

void ProviderBackend::setError(const QString &error)
{
    m_error = error;
    m_errorCount++;
    m_consecutiveErrors++;
    Q_EMIT errorChanged();
}

void ProviderBackend::clearError()
{
    if (!m_error.isEmpty()) {
        m_error.clear();
        m_consecutiveErrors = 0;
        Q_EMIT errorChanged();
    }
}

// --- Usage Data ---

qint64 ProviderBackend::inputTokens() const { return m_inputTokens; }
qint64 ProviderBackend::outputTokens() const { return m_outputTokens; }
qint64 ProviderBackend::totalTokens() const { return m_inputTokens + m_outputTokens; }
int ProviderBackend::requestCount() const { return m_requestCount; }
double ProviderBackend::cost() const { return m_cost; }
bool ProviderBackend::isEstimatedCost() const { return m_isEstimatedCost; }

void ProviderBackend::setInputTokens(qint64 tokens) { m_inputTokens = tokens; }
void ProviderBackend::setOutputTokens(qint64 tokens) { m_outputTokens = tokens; }
void ProviderBackend::setRequestCount(int count) { m_requestCount = count; }
void ProviderBackend::setCost(double cost) {
    m_cost = cost;
    m_isEstimatedCost = false;
    checkBudgetLimits();
}

// --- Budget ---

double ProviderBackend::dailyBudget() const { return m_dailyBudget; }
double ProviderBackend::monthlyBudget() const { return m_monthlyBudget; }
double ProviderBackend::dailyCost() const { return m_dailyCost; }
double ProviderBackend::monthlyCost() const { return m_monthlyCost; }

double ProviderBackend::estimatedMonthlyCost() const
{
    if (m_dailyCost <= 0 && m_monthlyCost <= 0) return 0.0;
    int dayOfMonth = QDate::currentDate().day();
    int daysInMonth = QDate::currentDate().daysInMonth();
    if (dayOfMonth == 0) return 0.0;

    // If we have real monthly cost data (e.g. OpenAI billing API), project it
    if (m_monthlyCost > 0) {
        return (m_monthlyCost / dayOfMonth) * daysInMonth;
    }
    // Fallback for estimated-cost providers: project daily cost to full month
    return m_dailyCost * daysInMonth;
}

void ProviderBackend::setDailyBudget(double budget)
{
    if (m_dailyBudget != budget) {
        m_dailyBudget = budget;
        Q_EMIT budgetChanged();
    }
}

void ProviderBackend::setMonthlyBudget(double budget)
{
    if (m_monthlyBudget != budget) {
        m_monthlyBudget = budget;
        Q_EMIT budgetChanged();
    }
}

void ProviderBackend::setDailyCost(double cost) {
    m_dailyCost = cost;
    checkBudgetLimits();
}
void ProviderBackend::setMonthlyCost(double cost) {
    m_monthlyCost = cost;
    checkBudgetLimits();
}

void ProviderBackend::checkBudgetLimits()
{
    if (m_dailyBudget > 0 && m_dailyCost >= m_dailyBudget) {
        Q_EMIT budgetExceeded(name(), QStringLiteral("daily"), m_dailyCost, m_dailyBudget);
    }
    if (m_monthlyBudget > 0 && m_monthlyCost >= m_monthlyBudget) {
        Q_EMIT budgetExceeded(name(), QStringLiteral("monthly"), m_monthlyCost, m_monthlyBudget);
    }
}

// --- Rate Limits ---

int ProviderBackend::rateLimitRequests() const { return m_rateLimitRequests; }
int ProviderBackend::rateLimitTokens() const { return m_rateLimitTokens; }
int ProviderBackend::rateLimitRequestsRemaining() const { return m_rateLimitRequestsRemaining; }
int ProviderBackend::rateLimitTokensRemaining() const { return m_rateLimitTokensRemaining; }
QString ProviderBackend::rateLimitResetTime() const { return m_rateLimitResetTime; }

void ProviderBackend::setRateLimitRequests(int limit) { m_rateLimitRequests = limit; }
void ProviderBackend::setRateLimitTokens(int limit) { m_rateLimitTokens = limit; }
void ProviderBackend::setRateLimitRequestsRemaining(int remaining) { m_rateLimitRequestsRemaining = remaining; }
void ProviderBackend::setRateLimitTokensRemaining(int remaining) { m_rateLimitTokensRemaining = remaining; }
void ProviderBackend::setRateLimitResetTime(const QString &time) { m_rateLimitResetTime = time; }

// --- Custom URL ---

QString ProviderBackend::customBaseUrl() const { return m_customBaseUrl; }
void ProviderBackend::setCustomBaseUrl(const QString &url)
{
    if (m_customBaseUrl != url) {
        m_customBaseUrl = url;
        Q_EMIT customBaseUrlChanged();
    }
}

QString ProviderBackend::effectiveBaseUrl(const char *defaultUrl) const
{
    if (!m_customBaseUrl.isEmpty()) {
        // Remove trailing slash for consistency
        QString url = m_customBaseUrl;
        while (url.endsWith(QLatin1Char('/'))) {
            url.chop(1);
        }
        return url;
    }
    return QLatin1String(defaultUrl);
}

// --- Metadata ---

QDateTime ProviderBackend::lastRefreshed() const { return m_lastRefreshed; }
int ProviderBackend::refreshCount() const { return m_refreshCount; }

void ProviderBackend::updateLastRefreshed()
{
    m_lastRefreshed = QDateTime::currentDateTime();
    m_refreshCount++;
}

// --- API Key ---

void ProviderBackend::setApiKey(const QString &key)
{
    m_apiKey = key;
    if (key.isEmpty()) {
        setConnected(false);
    }
}

bool ProviderBackend::hasApiKey() const
{
    return !m_apiKey.isEmpty();
}

QString ProviderBackend::apiKey() const
{
    return m_apiKey;
}

QNetworkAccessManager *ProviderBackend::networkManager() const
{
    return m_networkManager;
}

// --- Token-based Cost Estimation ---

void ProviderBackend::registerModelPricing(const QString &modelName, double inputPricePerMToken, double outputPricePerMToken)
{
    m_modelPricing.insert(modelName, ModelPricing{inputPricePerMToken, outputPricePerMToken});
}

void ProviderBackend::updateEstimatedCost(const QString &currentModel)
{
    // Only estimate if no real cost has been set by a billing API
    if (!m_isEstimatedCost && m_cost > 0) return;

    auto it = m_modelPricing.constFind(currentModel);
    if (it == m_modelPricing.constEnd()) {
        // Try prefix matching (e.g., "mistral-large-latest" could match "mistral-large")
        for (auto pit = m_modelPricing.constBegin(); pit != m_modelPricing.constEnd(); ++pit) {
            if (currentModel.startsWith(pit.key())) {
                it = pit;
                break;
            }
        }
    }
    if (it == m_modelPricing.constEnd()) return;

    double inputCost = (static_cast<double>(m_inputTokens) / 1000000.0) * it->inputPricePerMToken;
    double outputCost = (static_cast<double>(m_outputTokens) / 1000000.0) * it->outputPricePerMToken;
    double estimatedTotal = inputCost + outputCost;

    m_cost = estimatedTotal;
    m_isEstimatedCost = true;
    m_dailyCost = estimatedTotal; // Best estimate for daily cost from accumulated tokens
    checkBudgetLimits();
}
