#include "xaiprovider.h"

XAIProvider::XAIProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model (matches main.xml default)
    setModel(QStringLiteral("grok-3"));

    // Register model pricing ($ per 1M tokens) — xAI pricing as of 2026
    registerModelPricing(QStringLiteral("grok-3"), 3.0, 15.0);
    registerModelPricing(QStringLiteral("grok-3-mini"), 0.30, 0.50);
    registerModelPricing(QStringLiteral("grok-2"), 2.0, 10.0);
    registerModelPricing(QStringLiteral("grok-2-mini"), 2.0, 10.0);
}
