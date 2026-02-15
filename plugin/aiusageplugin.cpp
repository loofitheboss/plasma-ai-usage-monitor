#include "aiusageplugin.h"
#include "secretsmanager.h"
#include "providerbackend.h"
#include "openaiprovider.h"
#include "anthropicprovider.h"
#include "googleprovider.h"
#include "mistralprovider.h"
#include "deepseekprovider.h"
#include "groqprovider.h"
#include "xaiprovider.h"
#include "usagedatabase.h"

#include <QQmlEngine>

void AiUsagePlugin::registerTypes(const char *uri)
{
    Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.loofi.aiusagemonitor"));

    // Register C++ types for use in QML
    qmlRegisterType<SecretsManager>(uri, 1, 0, "SecretsManager");
    qmlRegisterType<OpenAIProvider>(uri, 1, 0, "OpenAIProvider");
    qmlRegisterType<AnthropicProvider>(uri, 1, 0, "AnthropicProvider");
    qmlRegisterType<GoogleProvider>(uri, 1, 0, "GoogleProvider");
    qmlRegisterType<MistralProvider>(uri, 1, 0, "MistralProvider");
    qmlRegisterType<DeepSeekProvider>(uri, 1, 0, "DeepSeekProvider");
    qmlRegisterType<GroqProvider>(uri, 1, 0, "GroqProvider");
    qmlRegisterType<XAIProvider>(uri, 1, 0, "XAIProvider");
    qmlRegisterType<UsageDatabase>(uri, 1, 0, "UsageDatabase");

    // Register abstract base as uncreatable (for type info in QML)
    qmlRegisterUncreatableType<ProviderBackend>(uri, 1, 0, "ProviderBackend",
        QStringLiteral("ProviderBackend is abstract; use a specific provider type."));
}
