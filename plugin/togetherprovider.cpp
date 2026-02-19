#include "togetherprovider.h"

TogetherProvider::TogetherProvider(QObject *parent)
    : OpenAICompatibleProvider(parent)
{
    // Set default model
    setModel(QStringLiteral("meta-llama/Llama-3.3-70B-Instruct-Turbo"));

    // Register model pricing ($ per 1M tokens) — Together AI pricing as of 2026
    registerModelPricing(QStringLiteral("meta-llama/Llama-3.3-70B-Instruct-Turbo"), 0.88, 0.88);
    registerModelPricing(QStringLiteral("meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo"), 0.18, 0.18);
    registerModelPricing(QStringLiteral("meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo"), 0.88, 0.88);
    registerModelPricing(QStringLiteral("meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo"), 3.50, 3.50);
    registerModelPricing(QStringLiteral("meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8"), 0.27, 0.85);
    registerModelPricing(QStringLiteral("meta-llama/Llama-4-Scout-17B-16E-Instruct"), 0.18, 0.30);
    registerModelPricing(QStringLiteral("Qwen/Qwen2.5-72B-Instruct-Turbo"), 1.20, 1.20);
    registerModelPricing(QStringLiteral("Qwen/Qwen2.5-7B-Instruct-Turbo"), 0.30, 0.30);
    registerModelPricing(QStringLiteral("deepseek-ai/DeepSeek-V3"), 0.90, 0.90);
    registerModelPricing(QStringLiteral("deepseek-ai/DeepSeek-R1"), 3.00, 7.00);
    registerModelPricing(QStringLiteral("mistralai/Mixtral-8x7B-Instruct-v0.1"), 0.60, 0.60);
    registerModelPricing(QStringLiteral("google/gemma-2-27b-it"), 0.80, 0.80);
}
