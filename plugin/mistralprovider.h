#ifndef MISTRALPROVIDER_H
#define MISTRALPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * Mistral AI provider backend.
 *
 * Queries:
 * - POST /v1/chat/completions (minimal) -- to read rate limit headers
 * - Uses x-ratelimit-* response headers for rate limits
 *
 * Models: mistral-large-latest, mistral-medium-latest, mistral-small-latest, codestral-latest
 */
class MistralProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit MistralProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("Mistral AI"); }
    QString iconName() const override { return QStringLiteral("globe"); }

    QString model() const;
    void setModel(const QString &model);

    Q_INVOKABLE void refresh() override;

Q_SIGNALS:
    void modelChanged();

private Q_SLOTS:
    void onCompletionReply(QNetworkReply *reply);

private:
    void fetchRateLimits();

    QString m_model = QStringLiteral("mistral-large-latest");

    static constexpr const char *BASE_URL = "https://api.mistral.ai/v1";
};

#endif // MISTRALPROVIDER_H
