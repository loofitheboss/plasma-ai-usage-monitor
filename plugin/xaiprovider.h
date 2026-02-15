#ifndef XAIPROVIDER_H
#define XAIPROVIDER_H

#include "providerbackend.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

/**
 * xAI/Grok provider backend.
 *
 * Uses OpenAI-compatible API at api.x.ai/v1.
 * - Rate limit headers: x-ratelimit-*
 * - Models endpoint for validation
 *
 * Models: grok-3, grok-3-mini, grok-2
 */
class XAIProvider : public ProviderBackend
{
    Q_OBJECT

    Q_PROPERTY(QString model READ model WRITE setModel NOTIFY modelChanged)

public:
    explicit XAIProvider(QObject *parent = nullptr);

    QString name() const override { return QStringLiteral("xAI"); }
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

    QString m_model = QStringLiteral("grok-3-mini");

    static constexpr const char *BASE_URL = "https://api.x.ai/v1";
};

#endif // XAIPROVIDER_H
