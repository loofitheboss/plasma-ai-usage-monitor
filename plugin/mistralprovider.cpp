#include "mistralprovider.h"

MistralProvider::MistralProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model
    setModel(QStringLiteral("mistral-large-latest"));

    // Register model pricing ($ per 1M tokens) — as of 2025
    registerModelPricing(QStringLiteral("mistral-large"), 2.0, 6.0);
    registerModelPricing(QStringLiteral("mistral-medium"), 2.7, 8.1);
    registerModelPricing(QStringLiteral("mistral-small"), 0.2, 0.6);
    registerModelPricing(QStringLiteral("codestral"), 0.3, 0.9);
    registerModelPricing(QStringLiteral("open-mistral-nemo"), 0.15, 0.15);
    registerModelPricing(QStringLiteral("pixtral"), 0.15, 0.15);
}
