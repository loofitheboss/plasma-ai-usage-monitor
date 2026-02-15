#include "providerbackend.h"

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

void ProviderBackend::setConnected(bool connected)
{
    if (m_connected != connected) {
        m_connected = connected;
        Q_EMIT connectedChanged();
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
    Q_EMIT errorChanged();
}

void ProviderBackend::clearError()
{
    if (!m_error.isEmpty()) {
        m_error.clear();
        Q_EMIT errorChanged();
    }
}

// --- Usage Data ---

qint64 ProviderBackend::inputTokens() const { return m_inputTokens; }
qint64 ProviderBackend::outputTokens() const { return m_outputTokens; }
qint64 ProviderBackend::totalTokens() const { return m_inputTokens + m_outputTokens; }
int ProviderBackend::requestCount() const { return m_requestCount; }
double ProviderBackend::cost() const { return m_cost; }

void ProviderBackend::setInputTokens(qint64 tokens) { m_inputTokens = tokens; }
void ProviderBackend::setOutputTokens(qint64 tokens) { m_outputTokens = tokens; }
void ProviderBackend::setRequestCount(int count) { m_requestCount = count; }
void ProviderBackend::setCost(double cost) { m_cost = cost; }

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

// --- Metadata ---

QDateTime ProviderBackend::lastRefreshed() const { return m_lastRefreshed; }
void ProviderBackend::updateLastRefreshed() { m_lastRefreshed = QDateTime::currentDateTime(); }

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

// --- Header parsing (base implementation, overridden by subclasses) ---

void ProviderBackend::parseRateLimitHeaders(QNetworkReply *reply)
{
    Q_UNUSED(reply)
    // Subclasses override with provider-specific header parsing
}
