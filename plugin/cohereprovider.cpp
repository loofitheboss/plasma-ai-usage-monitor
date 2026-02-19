#include "cohereprovider.h"

CohereProvider::CohereProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model
    setModel(QStringLiteral("command-a-03-2025"));

    // Register model pricing ($ per 1M tokens) — Cohere pricing as of 2026
    registerModelPricing(QStringLiteral("command-a-03-2025"), 2.50, 10.00);
    registerModelPricing(QStringLiteral("command-r-plus-08-2024"), 2.50, 10.00);
    registerModelPricing(QStringLiteral("command-r-plus"), 3.00, 15.00);
    registerModelPricing(QStringLiteral("command-r-08-2024"), 0.15, 0.60);
    registerModelPricing(QStringLiteral("command-r"), 0.50, 1.50);
    registerModelPricing(QStringLiteral("command-light"), 0.30, 0.60);
    registerModelPricing(QStringLiteral("command"), 1.00, 2.00);
}
