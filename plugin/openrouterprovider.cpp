#include "openrouterprovider.h"
#include <KLocalizedString>
#include <QNetworkRequest>
#include <QDebug>

OpenRouterProvider::OpenRouterProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model (OpenRouter uses provider/model format)
    setModel(QStringLiteral("openai/gpt-4o"));

    // Register model pricing ($ per 1M tokens) — OpenRouter pricing as of 2026
    // OpenRouter adds a small margin; these are approximate pass-through prices
    registerModelPricing(QStringLiteral("openai/gpt-4o"), 2.50, 10.00);
    registerModelPricing(QStringLiteral("openai/gpt-4o-mini"), 0.15, 0.60);
    registerModelPricing(QStringLiteral("openai/gpt-4.1"), 2.00, 8.00);
    registerModelPricing(QStringLiteral("openai/gpt-4.1-mini"), 0.40, 1.60);
    registerModelPricing(QStringLiteral("openai/gpt-4.1-nano"), 0.10, 0.40);
    registerModelPricing(QStringLiteral("openai/o3"), 2.00, 8.00);
    registerModelPricing(QStringLiteral("openai/o3-mini"), 1.10, 4.40);
    registerModelPricing(QStringLiteral("openai/o4-mini"), 1.10, 4.40);
    registerModelPricing(QStringLiteral("anthropic/claude-sonnet-4"), 3.00, 15.00);
    registerModelPricing(QStringLiteral("anthropic/claude-opus-4"), 15.00, 75.00);
    registerModelPricing(QStringLiteral("anthropic/claude-3.5-haiku"), 0.80, 4.00);
    registerModelPricing(QStringLiteral("google/gemini-2.5-pro"), 1.25, 10.00);
    registerModelPricing(QStringLiteral("google/gemini-2.5-flash"), 0.15, 0.60);
    registerModelPricing(QStringLiteral("google/gemini-2.0-flash"), 0.10, 0.40);
    registerModelPricing(QStringLiteral("meta-llama/llama-3.3-70b-instruct"), 0.39, 0.39);
    registerModelPricing(QStringLiteral("meta-llama/llama-4-maverick"), 0.20, 0.60);
    registerModelPricing(QStringLiteral("meta-llama/llama-4-scout"), 0.15, 0.35);
    registerModelPricing(QStringLiteral("deepseek/deepseek-chat-v3"), 0.14, 0.28);
    registerModelPricing(QStringLiteral("deepseek/deepseek-r1"), 0.55, 2.19);
    registerModelPricing(QStringLiteral("mistralai/mistral-large"), 2.00, 6.00);
    registerModelPricing(QStringLiteral("qwen/qwen-2.5-72b-instruct"), 0.36, 0.36);
    registerModelPricing(QStringLiteral("x-ai/grok-3"), 3.00, 15.00);
    registerModelPricing(QStringLiteral("x-ai/grok-3-mini"), 0.30, 0.50);
}

double OpenRouterProvider::credits() const { return m_credits; }

void OpenRouterProvider::refresh()
{
    if (!hasApiKey()) {
        setError(i18n("No API key configured"));
        setConnected(false);
        return;
    }

    // Call parent's refresh (chat completion for rate limits + usage)
    OpenAICompatibleProvider::refresh();

    // Additionally fetch credits balance
    fetchCredits();
}

void OpenRouterProvider::fetchCredits()
{
    // OpenRouter credits endpoint: GET /api/v1/auth/key
    QUrl url(QStringLiteral("%1/auth/key").arg(effectiveBaseUrl(defaultBaseUrl())));

    QNetworkRequest request = createRequest(url);

    addPendingRequest();
    int gen = currentGeneration();
    QNetworkReply *reply = networkManager()->get(request);
    trackReply(reply);
    connect(reply, &QNetworkReply::finished, this, [this, reply, gen]() {
        if (!isCurrentGeneration(gen)) { reply->deleteLater(); return; }
        onCreditsReply(reply);
    });
}

void OpenRouterProvider::onCreditsReply(QNetworkReply *reply)
{
    reply->deleteLater();
    decrementPendingRequest();

    if (reply->error() != QNetworkReply::NoError) {
        // Non-fatal: rate limit data may still be available
        qWarning() << "AI Usage Monitor: OpenRouter credits API error:" << reply->errorString();
        onAllRequestsDone();
        return;
    }

    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isNull()) {
        QJsonObject root = doc.object();
        // OpenRouter response: { "data": { "label": "...", "usage": 0.5, "limit": 10.0, ... } }
        QJsonObject dataObj = root.value(QStringLiteral("data")).toObject();
        double usage = dataObj.value(QStringLiteral("usage")).toDouble();
        double limit = dataObj.value(QStringLiteral("limit")).toDouble();
        // Credits remaining = limit - usage (if limit > 0)
        m_credits = (limit > 0) ? (limit - usage) : 0.0;
        Q_EMIT creditsChanged();
    }

    onAllRequestsDone();
}
